# frozen_string_literal: true

module Ci
  module Runners
    module RunnerCreationStrategies
      class InstanceRunnerStrategy
        attr_accessor :user, :type, :params

        def initialize(user:, type:, params:)
          @user = user
          @type = type
          @params = params
        end

        def normalize_params
          params[:runner_type] = :instance_type
        end

        def validate_params
          true
        end

        def authorized_user?
          user.present? && user.can?(:create_instance_runners)
        end
      end
    end
  end
end
