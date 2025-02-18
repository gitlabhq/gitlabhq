# frozen_string_literal: true

module Environments
  module FeatureFlags
    class ResetClientTokenService < BaseService
      def initialize(current_user:, feature_flags_client:)
        @current_user = current_user
        @feature_flags_client = feature_flags_client
      end

      def execute!
        return ServiceResponse.error(message: 'Not permitted to reset token') unless reset_permitted?

        feature_flags_client.reset_token!

        ServiceResponse.success
      end

      private

      attr_reader :feature_flags_client

      def reset_permitted?
        Ability.allowed?(current_user, :admin_feature_flags_client, feature_flags_client.project)
      end
    end
  end
end
