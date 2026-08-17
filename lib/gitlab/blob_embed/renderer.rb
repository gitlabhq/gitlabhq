# frozen_string_literal: true

module Gitlab
  module BlobEmbed
    # Fetches a range of lines from a repository blob at a given commit
    # and renders them as a syntax-highlighted snippet card.  The rendered
    # HTML is memoized in a content-addressed cache.
    #
    # This class does no permission checking: authorising access to the target
    # project is the caller's responsibility.
    class Renderer
      # Bump when the rendered markup changes.
      VERSION = 1

      # Maximum number of lines a single embed will render.
      MAX_LINES = 100

      # Maximum number of lines we'll highlight for a given embed.
      MAX_TO_LINES = 5000

      GITALY_ERRORS = [GRPC::BadStatus, Gitlab::Git::BaseError].freeze

      # `blob` may be a lazily-loaded Blob (see Blob.lazy) so that callers can
      # batch the Gitaly reads for several embeds; it is only accessed on a
      # cache miss. When omitted the blob is fetched on demand.
      #
      # `cross_project` is set when the embed's project differs from the project
      # the surrounding document belongs to; the header then shows the target's
      # full path to qualify it.
      def initialize(project:, sha:, path:, from:, to:, blob: nil, cross_project: false)
        @project = project
        @sha = sha
        @path = path
        @from = from
        @to = to
        @blob = blob
        @cross_project = cross_project
      end

      # Returns the embed HTML String, or nil if the blob cannot be embedded for any reason.
      #
      # Our references are content addressed (full SHA1!), so a blob that legitimately
      # cannot be embedded (like a binary) *never* can be: cache that result, too.
      # We don't cache read failures, though, so that it might retry on next load.
      def render
        return if out_of_range?

        Rails.cache.fetch(cache_key, expires_in: ::Blob::CACHE_TIME_IMMUTABLE) do
          build_html
        end
      rescue *GITALY_ERRORS => e
        Gitlab::ErrorTracking.track_exception(e, project_id: project.id)
        nil
      end

      private

      attr_reader :project, :sha, :path, :from, :to, :cross_project

      # A lazy Blob is truthy even when it resolves to nil, so a caller that
      # supplied one always keeps it. Only callers that didn't pass one trigger
      # reads here.
      def blob
        @blob ||= project.repository.blob_at(sha, path)
      end

      def out_of_range?
        from < 1 || to < from || (to - from + 1) > MAX_LINES || to > MAX_TO_LINES
      end

      def cache_key
        ['blob_embed', VERSION, project.id, sha, path, from, to, cross_project]
      end

      def build_html
        return if blob.nil? || blob.stored_externally?

        return if blob.size > ::Gitlab::Git::Blob::MAX_DATA_DISPLAY_SIZE

        blob.load_all_data!
        return if blob.binary?

        line_count = blob.data.each_line.count
        return if from > line_count

        html = Blobs::EmbeddedBlobComponent.new(
          blob: blob.present,
          project: project,
          sha: sha,
          from: from,
          to: [to, line_count].min,
          cross_project: cross_project
        ).render_in(view_context)

        strip_view_annotations(html)
      end

      # Remove the "<!-- BEGIN app/components/blobs/embedded_blob_component.html.haml -->"
      # comment (and its "<!-- END ... -->" pair) added in development mode, otherwise
      # they become visible in the content editor. There's no other comments added,
      # so we just remove every comment.
      def strip_view_annotations(html)
        return html unless ActionView::Base.annotate_rendered_view_with_filenames

        fragment = Nokogiri::HTML5.fragment(html)
        fragment.xpath('.//comment()').remove
        fragment.to_html
      end

      def view_context
        ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
      end
    end
  end
end
