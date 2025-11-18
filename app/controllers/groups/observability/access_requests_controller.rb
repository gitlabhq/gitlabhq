# frozen_string_literal: true

module Groups
  module Observability
    class AccessRequestsController < Groups::ApplicationController
      before_action :authenticate_user!
      before_action :authorize_request_access!

      feature_category :observability
      urgency :low

      def new; end

      def create
        if group.observability_group_o11y_setting.present?
          flash[:alert] = s_('Observability|Observability is already enabled for this group')
        else
          result = ::Observability::AccessRequestService.new(
            group,
            current_user
          ).execute

          if result.success?
            flash[:success] = s_('Observability|Welcome to GitLab Observability!')
          else
            flash[:alert] = result.message
          end
        end

        redirect_to group_observability_setup_path(group)
      end

      private

      def authorize_request_access!
        return render_404 unless ::Feature.enabled?(:observability_sass_features, group)

        return if Ability.allowed?(current_user, :create_observability_access_request, group)

        render_403
      end
    end
  end
end
