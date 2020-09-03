# frozen_string_literal: true

module Operations
  module FeatureFlags
    class Strategy < ApplicationRecord
      STRATEGY_DEFAULT = 'default'
      STRATEGY_GITLABUSERLIST = 'gitlabUserList'
      STRATEGY_GRADUALROLLOUTUSERID = 'gradualRolloutUserId'
      STRATEGY_USERWITHID = 'userWithId'
      STRATEGIES = {
        STRATEGY_DEFAULT => [].freeze,
        STRATEGY_GITLABUSERLIST => [].freeze,
        STRATEGY_GRADUALROLLOUTUSERID => %w[groupId percentage].freeze,
        STRATEGY_USERWITHID => ['userIds'].freeze
      }.freeze
      USERID_MAX_LENGTH = 256

      self.table_name = 'operations_strategies'

      belongs_to :feature_flag
      has_many :scopes, class_name: 'Operations::FeatureFlags::Scope'
      has_one :strategy_user_list
      has_one :user_list, through: :strategy_user_list

      validates :name,
        inclusion: {
        in: STRATEGIES.keys,
        message: 'strategy name is invalid'
      }

      validate :parameters_validations, if: -> { errors[:name].blank? }
      validates :user_list, presence: true, if: -> { name == STRATEGY_GITLABUSERLIST }
      validates :user_list, absence: true, if: -> { name != STRATEGY_GITLABUSERLIST }
      validate :same_project_validation, if: -> { user_list.present? }

      accepts_nested_attributes_for :scopes, allow_destroy: true

      def user_list_id=(user_list_id)
        self.user_list = ::Operations::FeatureFlags::UserList.find(user_list_id)
      end

      private

      def same_project_validation
        unless user_list.project_id == feature_flag.project_id
          errors.add(:user_list, 'must belong to the same project')
        end
      end

      def parameters_validations
        validate_parameters_type &&
          validate_parameters_keys &&
          validate_parameters_values
      end

      def validate_parameters_type
        parameters.is_a?(Hash) || parameters_error('parameters are invalid')
      end

      def validate_parameters_keys
        actual_keys = parameters.keys.sort
        expected_keys = STRATEGIES[name].sort
        expected_keys == actual_keys || parameters_error('parameters are invalid')
      end

      def validate_parameters_values
        case name
        when STRATEGY_GRADUALROLLOUTUSERID
          gradual_rollout_user_id_parameters_validation
        when STRATEGY_USERWITHID
          FeatureFlagUserXidsValidator.validate_user_xids(self, :parameters, parameters['userIds'], 'userIds')
        end
      end

      def gradual_rollout_user_id_parameters_validation
        percentage = parameters['percentage']
        group_id = parameters['groupId']

        unless percentage.is_a?(String) && percentage.match(/\A[1-9]?[0-9]\z|\A100\z/)
          parameters_error('percentage must be a string between 0 and 100 inclusive')
        end

        unless group_id.is_a?(String) && group_id.match(/\A[a-z]{1,32}\z/)
          parameters_error('groupId parameter is invalid')
        end
      end

      def parameters_error(message)
        errors.add(:parameters, message)
        false
      end
    end
  end
end
