# frozen_string_literal: true

module Projects
  module Settings
    class MergeRequestsController < Projects::ApplicationController
      layout 'project_settings'

      before_action :merge_requests_enabled?
      before_action :present_project, only: [:edit]
      before_action :authorize_admin_project!

      feature_category :code_review_workflow

      def update
        result = ::Projects::UpdateService.new(@project, current_user, project_params).execute

        if result[:status] == :success
          flash[:notice] = format(_("Project '%{project_name}' was successfully updated."), project_name: @project.name)
          redirect_to project_settings_merge_requests_path(@project)
        else
          # Refresh the repo in case anything changed
          @repository = @project.repository.reset

          flash[:alert] = result[:message]
          @project.reset
          render 'show'
        end
      end

      private

      def merge_requests_enabled?
        render_404 unless @project.merge_requests_enabled?
      end

      def project_params
        params.require(:project)
          .permit(project_params_attributes)
      end

      def project_setting_attributes
        %i[
          squash_option
          allow_editing_commit_messages
          mr_default_target_self
        ]
      end

      def project_params_attributes
        [
          :allow_merge_on_skipped_pipeline,
          :resolve_outdated_diff_discussions,
          :only_allow_merge_if_all_discussions_are_resolved,
          :only_allow_merge_if_pipeline_succeeds,
          :allow_merge_without_pipeline,
          :printing_merge_request_link_enabled,
          :remove_source_branch_after_merge,
          :merge_method,
          :merge_commit_template_or_default,
          :squash_commit_template_or_default,
          :suggestion_commit_message
        ] + [project_setting_attributes: project_setting_attributes]
      end
    end
  end
end

Projects::Settings::MergeRequestsController.prepend_mod_with('Projects::Settings::MergeRequestsController')
