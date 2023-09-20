# frozen_string_literal: true

class Projects::PagesController < Projects::ApplicationController
  before_action :require_pages_enabled!
  before_action :authorize_read_pages!, only: [:show]
  before_action :authorize_update_pages!, except: [:show, :destroy]
  before_action :authorize_remove_pages!, only: [:destroy]

  feature_category :pages

  def new
    @pipeline_wizard_data = {
      project_path: @project.full_path,
      default_branch: @project.repository.root_ref,
      redirect_to_when_done: project_pages_path(@project)
    }
  end

  def show
    unless @project.pages_enabled?
      render :disabled
      return
    end

    if @project.pages_show_onboarding?
      redirect_to action: 'new'
      return
    end

    # rubocop: disable CodeReuse/ActiveRecord
    @domains = @project.pages_domains.order(:domain).present(current_user: current_user)
    # rubocop: enable CodeReuse/ActiveRecord
  end

  def destroy
    ::Pages::DeleteService.new(@project, current_user).execute

    respond_to do |format|
      format.html do
        redirect_to project_pages_path(@project), status: :found, notice: 'Pages were scheduled for removal'
      end
    end
  end

  def update
    result = Projects::UpdateService.new(@project, current_user, project_params).execute

    respond_to do |format|
      format.html do
        if result[:status] == :success
          flash[:notice] = 'Your changes have been saved'
        else
          flash[:alert] = result[:message]
        end

        redirect_to project_pages_path(@project)
      end
    end
  end

  private

  def project_params
    params.require(:project).permit(project_params_attributes)
  end

  def project_params_attributes
    [
      :pages_https_only,
      { project_setting_attributes: project_setting_attributes }
    ]
  end

  # overridden in EE
  def project_setting_attributes
    [:pages_unique_domain_enabled]
  end
end

Projects::PagesController.prepend_mod_with('Projects::PagesController')
