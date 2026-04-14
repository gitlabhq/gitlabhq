# frozen_string_literal: true

module Groups
  module Observability
    class BaseController < Groups::ApplicationController
      before_action :authenticate_user!
      before_action :authorize_request_access!

      feature_category :observability
      urgency :low

      private

      def authorize_request_access!
        return render_404 unless ::Feature.enabled?(:observability_sass_features, group)

        return if Ability.allowed?(current_user, :create_observability_access_request, group)

        render_404
      end
    end
  end
end
