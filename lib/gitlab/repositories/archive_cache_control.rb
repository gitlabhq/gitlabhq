# frozen_string_literal: true

module Gitlab
  module Repositories
    # Computes the HTTP caching directives for repository archive responses so
    # that the web controller and the REST API emit equivalent Cache-Control
    # and ETag headers. Grape has no equivalent of Rails' `expires_in` /
    # `fresh_when`, so the API builds its headers from #cache_control and #etag.
    class ArchiveCacheControl
      # Cache-Control directives shared by both archive endpoints.
      STALE_IF_ERROR = 5.minutes
      STALE_WHILE_REVALIDATE = 1.minute
      SHARED_MAX_AGE = 1.minute

      def initialize(project, ref:, metadata:, include_lfs_blobs: true, exclude_paths: [])
        @project = project
        @ref = ref
        @metadata = metadata
        @include_lfs_blobs = include_lfs_blobs
        @exclude_paths = exclude_paths
      end

      # A branch or tag can move, so the archive it points at is cached briefly.
      # An archive addressed by its commit SHA is immutable and cached longer.
      def max_age
        if ref == commit_id
          Repository::ARCHIVE_CACHE_TIME_IMMUTABLE
        else
          Repository::ARCHIVE_CACHE_TIME
        end
      end

      # Only mark archives shared-cacheable when an anonymous user could download
      # them, so shared caches never store private or internal repositories.
      def public?
        ::Users::Anonymous.can?(:download_code, project)
      end

      # `include_lfs_blobs` and `exclude_paths` change the archive contents but
      # are not encoded in ArchivePath, so they must vary the ETag. They are
      # appended only when non-default (the web archive always uses the defaults),
      # which keeps the web ETag unchanged.
      def etag_components
        components = [commit_id, metadata['ArchivePath']]
        components << include_lfs_blobs unless include_lfs_blobs
        components << exclude_paths if exclude_paths.present?
        components
      end

      # Full Cache-Control header value, mirroring the directives the web
      # controller passes to Rails' `expires_in`.
      def cache_control
        [
          "max-age=#{max_age.to_i}",
          public? ? 'public' : 'private',
          'must-revalidate',
          "stale-while-revalidate=#{STALE_WHILE_REVALIDATE.to_i}",
          "stale-if-error=#{STALE_IF_ERROR.to_i}",
          "s-maxage=#{SHARED_MAX_AGE.to_i}"
        ].join(', ')
      end

      # Mirrors the strong ETag produced by Rails' `fresh_when(strong_etag:)` so
      # API and web archive responses are validated identically.
      def etag
        %("#{ActiveSupport::Digest.hexdigest(ActiveSupport::Cache.expand_cache_key(etag_components))}")
      end

      private

      attr_reader :project, :ref, :metadata, :include_lfs_blobs, :exclude_paths

      def commit_id
        metadata['CommitId']
      end
    end
  end
end
