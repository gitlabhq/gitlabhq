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
        result = ::Observability::AccessRequestService.new(
          group,
          current_user
        ).execute

        return if result.success?

        flash.now[:alert] = result.message
        render :new, status: :unprocessable_entity
      end

      private

      def authorize_request_access!
        return render_404 if group.observability_group_o11y_setting.present?
        return render_404 unless ::Feature.enabled?(:observability_sass_features, group)

        return if Ability.allowed?(current_user, :create_observability_access_request, group)

        render_403
      end
    end
  end
end
