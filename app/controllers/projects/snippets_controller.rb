# frozen_string_literal: true

class Projects::SnippetsController < Projects::ApplicationController
  include RendersNotes
  include ToggleAwardEmoji
  include SpammableActions
  include SnippetsActions
  include RendersBlob
  include PaginatedCollection
  include Gitlab::NoteableMetadata

  skip_before_action :verify_authenticity_token,
    if: -> { action_name == 'show' && js_request? }

  before_action :check_snippets_available!
  before_action :snippet, only: [:show, :edit, :destroy, :update, :raw, :toggle_award_emoji, :mark_as_spam]

  # Allow create snippet
  before_action :authorize_create_snippet!, only: [:new, :create]

  # Allow read any snippet
  before_action :authorize_read_snippet!, except: [:new, :create, :index]

  # Allow modify snippet
  before_action :authorize_update_snippet!, only: [:edit, :update]

  # Allow destroy snippet
  before_action :authorize_admin_snippet!, only: [:destroy]

  respond_to :html

  def index
    @snippet_counts = Snippets::CountService
      .new(current_user, project: @project)
      .execute

    @snippets = SnippetsFinder.new(current_user, project: @project, scope: params[:scope])
      .execute
      .page(params[:page])
      .inc_author

    return if redirect_out_of_range(@snippets)

    @noteable_meta_data = noteable_meta_data(@snippets, 'Snippet')
  end

  def new
    @snippet = @noteable = @project.snippets.build
  end

  def create
    create_params = snippet_params.merge(spammable_params)
    service_response = Snippets::CreateService.new(project, current_user, create_params).execute
    @snippet = service_response.payload[:snippet]

    handle_repository_error(:new)
  end

  def update
    update_params = snippet_params.merge(spammable_params)

    service_response = Snippets::UpdateService.new(project, current_user, update_params).execute(@snippet)
    @snippet = service_response.payload[:snippet]

    handle_repository_error(:edit)
  end

  def show
    conditionally_expand_blob(blob)

    respond_to do |format|
      format.html do
        @note = @project.notes.new(noteable: @snippet)
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

  def destroy
    service_response = Snippets::DestroyService.new(current_user, @snippet).execute

    if service_response.success?
      redirect_to project_snippets_path(project), status: :found
    elsif service_response.http_status == 403
      access_denied!
    else
      redirect_to project_snippet_path(project, @snippet),
                  status: :found,
                  alert: service_response.message
    end
  end

  protected

  def snippet
    @snippet ||= @project.snippets.inc_relations_for_view.find(params[:id])
  end
  alias_method :awardable, :snippet
  alias_method :spammable, :snippet

  def spammable_path
    project_snippet_path(@project, @snippet)
  end

  def authorize_read_snippet!
    return render_404 unless can?(current_user, :read_snippet, @snippet)
  end

  def authorize_update_snippet!
    return render_404 unless can?(current_user, :update_snippet, @snippet)
  end

  def authorize_admin_snippet!
    return render_404 unless can?(current_user, :admin_snippet, @snippet)
  end

  def snippet_params
    params.require(:project_snippet).permit(:title, :content, :file_name, :private, :visibility_level, :description)
  end
end
