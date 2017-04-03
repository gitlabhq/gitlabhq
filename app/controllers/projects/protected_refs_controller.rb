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
    self.protected_ref = create_service.new(@project, current_user, protected_ref_params).execute
    unless protected_ref.persisted?
      flash[:alert] = protected_ref.errors.full_messages.join(', ').html_safe
    end
    redirect_to_repository_settings(@project)
  end

  def show
    self.matching_refs = protected_ref.matching(project_refs)
  end

  def update
    self.protected_ref = update_service.new(@project, current_user, protected_ref_params).execute(protected_ref)

    if protected_ref.valid?
      respond_to do |format|
        format.json { render json: protected_ref, status: :ok }
      end
    else
      respond_to do |format|
        format.json { render json: protected_ref.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    protected_ref.destroy

    respond_to do |format|
      format.html { redirect_to_repository_settings(@project) }
      format.js { head :ok }
    end
  end
end
