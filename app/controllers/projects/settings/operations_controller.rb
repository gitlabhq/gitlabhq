# frozen_string_literal: true

module Projects
  module Settings
    class OperationsController < Projects::ApplicationController
      before_action :check_license
      before_action :authorize_update_environment!

      def show
      end

      def update
        result = ::Projects::Operations::UpdateService.new(project, current_user, update_params).execute

        if result[:status] == :success
          flash[:notice] = _('Your changes have been saved')
          redirect_to project_settings_operations_path(@project)
        else
          render 'show'
        end
      end

      private

      def update_params
        params.require(:project).permit(permitted_project_params)
      end

      # overridden in EE
      def permitted_project_params
        {}
      end

      def check_license
        render_404 unless helpers.settings_operations_available?
      end
    end
  end
end
