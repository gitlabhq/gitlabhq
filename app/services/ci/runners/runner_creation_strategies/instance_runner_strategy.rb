# frozen_string_literal: true

module Ci
  module Runners
    module RunnerCreationStrategies
      class InstanceRunnerStrategy
        def initialize(user:, params:)
          @user = user
          @params = params
        end

        def normalize_params
          params[:runner_type] = 'instance_type'
          params[:organization_id] = nil
        end

        def validate_params
          _('Unexpected scope') if params[:scope]
        end

        def authorized_user?
          user.present? && user.can?(:create_instance_runners)
        end

        private

        attr_reader :user, :params
      end
    end
  end
end
