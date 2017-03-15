class Projects::ProtectedTagsController < Projects::ApplicationController
  include RepositorySettingsRedirect
  # Authorize
  before_action :require_non_empty_project
  before_action :authorize_admin_project!
  before_action :load_protected_tag, only: [:show, :update, :destroy]

  layout "project_settings"

  def index
    redirect_to_repository_settings(@project)
  end

  def create
    @protected_tag = ::ProtectedTags::CreateService.new(@project, current_user, protected_tag_params).execute
    unless @protected_tag.persisted?
      flash[:alert] = @protected_tags.errors.full_messages.join(', ').html_safe
    end
    redirect_to_repository_settings(@project)
  end

  def show
    @matching_tags = @protected_tag.matching(@project.repository.tags)
  end

  def update
    @protected_tag = ::ProtectedTags::UpdateService.new(@project, current_user, protected_tag_params).execute(@protected_tag)

    if @protected_tag.valid?
      respond_to do |format|
        format.json { render json: @protected_tag, status: :ok }
      end
    else
      respond_to do |format|
        format.json { render json: @protected_tag.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @protected_tag.destroy

    respond_to do |format|
      format.html { redirect_to_repository_settings(@project) }
      format.js { head :ok }
    end
  end

  private

  def load_protected_tag
    @protected_tag = @project.protected_tags.find(params[:id])
  end

  def protected_tag_params
    params.require(:protected_tag).permit(:name, push_access_levels_attributes: [:access_level, :id])
  end
end
