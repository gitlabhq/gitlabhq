# frozen_string_literal: true

module SnippetsActions
  extend ActiveSupport::Concern

  include RendersNotes
  include RendersBlob
  include PaginatedCollection
  include Gitlab::NoteableMetadata
  include Snippets::SendBlob
  include SnippetsSort
  include ProductAnalyticsTracking

  included do
    skip_before_action :verify_authenticity_token,
      if: -> { action_name == 'show' && js_request? }

    track_event :show, name: 'i_snippets_show'

    respond_to :html
  end

  def edit; end

  # This endpoint is being replaced by Snippets::BlobController#raw
  # Support for old raw links will be maintainted via this action but
  # it will only return the first blob found,
  # see: https://gitlab.com/gitlab-org/gitlab/-/issues/217775
  def raw
    workhorse_set_content_type!

    # Until we don't migrate all snippets to version
    # snippets we need to support old `SnippetBlob`
    # blobs
    if defined?(blob.snippet)
      send_data(
        convert_line_endings(blob.data),
        type: 'text/plain; charset=utf-8',
        disposition: content_disposition,
        filename: Snippet.sanitized_file_name(blob.name)
      )
    else
      send_snippet_blob(snippet, blob)
    end
  end

  def js_request?
    request.format.js?
  end

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def show
    respond_to do |format|
      format.html do
        @note = Note.new(noteable: @snippet, project: @snippet.project)
        @noteable = @snippet

        @discussions = @snippet.discussions
        @notes = prepare_notes_for_rendering(@discussions.flat_map(&:notes))
        render 'show'
      end

      format.js do
        if @snippet.embeddable?
          conditionally_expand_blobs(blobs)

          render 'shared/snippets/show'
        else
          head :not_found
        end
      end
    end
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  private

  def blob
    @blob ||= blobs.first
  end

  def blobs
    @blobs ||= if snippet.empty_repo?
                 [snippet.blob]
               else
                 snippet.blobs
               end
  end

  def convert_line_endings(content)
    params[:line_ending] == 'raw' ? content : content.gsub(/\r\n/, "\n")
  end
end
