# frozen_string_literal: true

class Projects::PagesController < Projects::ApplicationController
  layout 'project_settings'

  before_action :require_pages_enabled!
  before_action :authorize_read_pages!, only: [:show]
  before_action :authorize_update_pages!, except: [:show, :destroy]
  before_action :authorize_remove_pages!, only: [:destroy]

  # rubocop: disable CodeReuse/ActiveRecord
  def show
    @domains = @project.pages_domains.order(:domain)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def destroy
    ::Pages::DeleteService.new(@project, current_user).execute

    respond_to do |format|
      format.html do
        redirect_to project_pages_path(@project),
                    status: :found,
                    notice: 'Pages were removed'
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
    %i[pages_https_only]
  end
end

Projects::PagesController.prepend_if_ee('EE::Projects::PagesController')
