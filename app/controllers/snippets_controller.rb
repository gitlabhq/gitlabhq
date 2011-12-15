class SnippetsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :project
  layout "project"

  # Authorize
  before_filter :add_project_abilities

  # Allow read any snippet
  before_filter :authorize_read_snippet!

  # Allow write(create) snippet
  before_filter :authorize_write_snippet!, :only => [:new, :create]

  # Allow modify snippet
  before_filter :authorize_modify_snippet!, :only => [:edit, :update]

  # Allow destroy snippet
  before_filter :authorize_admin_snippet!, :only => [:destroy]

  respond_to :html

  def index
    @snippets = @project.snippets
  end

  def new
    @snippet = @project.snippets.new
  end

  def create
    @snippet = @project.snippets.new(params[:snippet])
    @snippet.author = current_user
    @snippet.save

    if @snippet.valid?
      redirect_to [@project, @snippet]
    else
      respond_with(@snippet)
    end
  end

  def edit
    @snippet = @project.snippets.find(params[:id])
  end

  def update
    @snippet = @project.snippets.find(params[:id])
    @snippet.update_attributes(params[:snippet])

    if @snippet.valid?
      redirect_to [@project, @snippet]
    else
      respond_with(@snippet)
    end
  end

  def show
    @snippet = @project.snippets.find(params[:id])
    @notes = @snippet.notes
    @note = @project.notes.new(:noteable => @snippet)
  end

  def destroy
    @snippet = @project.snippets.find(params[:id])

    return access_denied! unless can?(current_user, :admin_snippet, @snippet)

    @snippet.destroy

    redirect_to project_snippets_path(@project)
  end

  protected

  def authorize_modify_snippet!
    can?(current_user, :modify_snippet, @snippet)
  end

  def authorize_admin_snippet!
    can?(current_user, :admin_snippet, @snippet)
  end
end
