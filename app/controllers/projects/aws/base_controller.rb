# frozen_string_literal: true

module Projects
  module Aws
    class BaseController < Projects::ApplicationController
      feature_category :not_owned # rubocop:disable Gitlab/AvoidFeatureCategoryNotOwned -- removing code in https://gitlab.com/gitlab-org/gitlab/-/issues/478491
      urgency :low

      before_action :admin_project_aws!
      before_action :feature_flag_enabled!

      def admin_project_aws!
        return if can?(current_user, :admin_project_aws, project)

        track_event(:error_invalid_user)
        access_denied!
      end

      def feature_flag_enabled!
        return if Feature.enabled?(:cloudseed_aws, current_user)
        return if Feature.enabled?(:cloudseed_aws, project.group)
        return if Feature.enabled?(:cloudseed_aws, project)

        track_event(:error_feature_flag_not_enabled)
        access_denied!
      end

      def track_event(action, label = nil)
        Gitlab::Tracking.event(
          self.class.name,
          action.to_s,
          label: label,
          project: project,
          user: current_user
        )
      end
    end
  end
end
