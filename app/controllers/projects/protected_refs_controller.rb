class Projects::ProtectedRefsController < Projects::ApplicationController
  include RepositorySettingsRedirect

  # Authorize
  before_action :require_non_empty_project
  before_action :authorize_admin_project!
  before_action :load_protected_ref, only: [:show, :update, :destroy]

  layout "project_settings"

  def index
    redirect_to_repository_settings(@project)
  end

  def create
    protected_ref = create_service_class.new(@project, current_user, protected_ref_params).execute

    unless protected_ref.persisted?
      flash[:alert] = protected_ref.errors.full_messages.join(', ').html_safe
    end

    redirect_to_repository_settings(@project)
  end

  def show
    @matching_refs = @protected_ref.matching(project_refs)
  end

  def update
    @protected_ref = update_service_class.new(@project, current_user, protected_ref_params).execute(@protected_ref)

    if @protected_ref.valid?
      render json: @protected_ref, status: :ok
    else
      render json: @protected_ref.errors, status: :unprocessable_entity
    end
  end

  def destroy
    destroy_service_class.new(@project, current_user).execute(@protected_ref)

    respond_to do |format|
      format.html { redirect_to_repository_settings(@project) }
      format.js { head :ok }
    end
  end

  protected

  def create_service_class
    service_namespace::CreateService
  end

  def update_service_class
    service_namespace::UpdateService
  end

  def destroy_service_class
    service_namespace::DestroyService
  end

  def access_level_attributes
    %i(access_level id)
  end
end
