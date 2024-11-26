# frozen_string_literal: true

module Ci
  module Runners
    module RunnerCreationStrategies
      class GroupRunnerStrategy
        include Gitlab::Utils::StrongMemoize

        def initialize(user:, params:)
          @user = user
          @params = params
        end

        def normalize_params
          params.merge!({
            runner_type: 'group_type',
            sharding_key_id: scope&.id,
            groups: [scope]
          })
        end

        def validate_params
          _('Missing/invalid group') unless scope.present?
        end

        def authorized_user?
          user.present? && user.can?(:create_runner, scope)
        end

        private

        attr_reader :user, :params

        def scope
          params.delete(:scope)
        end
        strong_memoize_attr :scope
      end
    end
  end
end
