# frozen_string_literal: true

module Groups
  module Settings
    class MergeRequestsController < Groups::ApplicationController
      layout 'group_settings'

      before_action :authorize_manage_merge_request_settings!

      feature_category :code_review_workflow

      def update
        if Groups::UpdateService.new(@group, current_user, group_settings_params).execute
          notice = format(
            _("Group '%{group_name}' was successfully updated."),
            group_name: @group.name
          )
          redirect_to edit_group_path(@group, anchor: 'js-merge-requests-settings'), notice: notice
        else
          @group.reset
          alert = @group.errors.full_messages.to_sentence.presence || format(
            _("Group '%{group_name}' could not be updated."),
            group_name: @group.name
          )
          redirect_to edit_group_path(@group, anchor: 'js-merge-requests-settings'), alert: alert
        end
      end

      private

      def group_settings_params
        params.require(:namespace_setting).permit(permitted_group_settings_params)
      end

      def permitted_group_settings_params
        %i[require_sha_for_merge lock_require_sha_for_merge]
      end
    end
  end
end

Groups::Settings::MergeRequestsController.prepend_mod
