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

  # Allow read any snippet
  before_action :authorize_read_project_snippet!, except: [:new, :create, :index]

  # Allow write(create) snippet
  before_action :authorize_create_project_snippet!, only: [:new, :create]

  # Allow modify snippet
  before_action :authorize_update_project_snippet!, only: [:edit, :update]

  # Allow destroy snippet
  before_action :authorize_admin_project_snippet!, only: [:destroy]

  respond_to :html

  def index
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

    @snippet = CreateSnippetService.new(@project, current_user, create_params).execute

    recaptcha_check_with_fallback { render :new }
  end

  def update
    update_params = snippet_params.merge(spammable_params)

    UpdateSnippetService.new(project, current_user, @snippet, update_params).execute

    recaptcha_check_with_fallback { render :edit }
  end

  def show
    blob = @snippet.blob
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
    return access_denied! unless can?(current_user, :admin_project_snippet, @snippet)

    @snippet.destroy

    redirect_to project_snippets_path(@project), status: :found
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

  def authorize_read_project_snippet!
    return render_404 unless can?(current_user, :read_project_snippet, @snippet)
  end

  def authorize_update_project_snippet!
    return render_404 unless can?(current_user, :update_project_snippet, @snippet)
  end

  def authorize_admin_project_snippet!
    return render_404 unless can?(current_user, :admin_project_snippet, @snippet)
  end

  def snippet_params
    params.require(:project_snippet).permit(:title, :content, :file_name, :private, :visibility_level, :description)
  end
end
