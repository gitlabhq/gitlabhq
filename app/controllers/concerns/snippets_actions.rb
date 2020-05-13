# frozen_string_literal: true

module SnippetsActions
  extend ActiveSupport::Concern
  include SendsBlob

  included do
    before_action :redirect_if_binary, only: [:edit, :update]
  end

  def edit
    # We need to load some info from the existing blob
    snippet.content = blob.data
    snippet.file_name = blob.path

    render 'edit'
  end

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
      send_blob(
        snippet.repository,
        blob,
        inline: content_disposition == 'inline',
        allow_caching: snippet.public?
      )
    end
  end

  def js_request?
    request.format.js?
  end

  private

  def content_disposition
    @disposition ||= params[:inline] == 'false' ? 'attachment' : 'inline'
  end

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def blob
    return unless snippet

    @blob ||= if snippet.empty_repo?
                snippet.blob
              else
                snippet.blobs.first
              end
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  def convert_line_endings(content)
    params[:line_ending] == 'raw' ? content : content.gsub(/\r\n/, "\n")
  end

  def handle_repository_error(action)
    errors = Array(snippet.errors.delete(:repository))

    flash.now[:alert] = errors.first if errors.present?

    recaptcha_check_with_fallback(errors.empty?) { render action }
  end

  def redirect_if_binary
    redirect_to gitlab_snippet_path(snippet) if blob&.binary?
  end
end
