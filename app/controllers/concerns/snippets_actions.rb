# frozen_string_literal: true

module SnippetsActions
  extend ActiveSupport::Concern

  include RendersNotes
  include RendersBlob
  include PaginatedCollection
  include Gitlab::NoteableMetadata
  include Snippets::SendBlob

  included do
    skip_before_action :verify_authenticity_token,
      if: -> { action_name == 'show' && js_request? }

    before_action :redirect_if_binary, only: [:edit, :update]

    respond_to :html
  end

  def edit
    # We need to load some info from the existing blob
    snippet.content = blob.data
    snippet.file_name = blob.path

    render 'edit'
  end

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
    conditionally_expand_blob(blob)

    respond_to do |format|
      format.html do
        @note = Note.new(noteable: @snippet, project: @snippet.project)
        @noteable = @snippet

        @discussions = @snippet.discussions
        @notes = prepare_notes_for_rendering(@discussions.flat_map(&:notes), @noteable)
        render 'show'
      end

      format.json do
        render_blob_json(blob)
      end

      format.js do
        if @snippet.embeddable?
          render 'shared/snippets/show'
        else
          head :not_found
        end
      end
    end
  end

  def update
    update_params = snippet_params.merge(spammable_params)

    service_response = Snippets::UpdateService.new(@snippet.project, current_user, update_params).execute(@snippet)
    @snippet = service_response.payload[:snippet]

    handle_repository_error(:edit)
  end

  def destroy
    service_response = Snippets::DestroyService.new(current_user, @snippet).execute

    if service_response.success?
      redirect_to gitlab_dashboard_snippets_path(@snippet), status: :found
    elsif service_response.http_status == 403
      access_denied!
    else
      redirect_to gitlab_snippet_path(@snippet),
                  status: :found,
                  alert: service_response.message
    end
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  private

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
