# frozen_string_literal: true

module Operations
  module FeatureFlags
    class UserList < ApplicationRecord
      include AtomicInternalId
      include IidRoutes

      self.table_name = 'operations_user_lists'

      belongs_to :project
      has_many :strategy_user_lists
      has_many :strategies, through: :strategy_user_lists

      has_internal_id :iid, scope: :project, init: ->(s) { s&.project&.operations_feature_flags_user_lists&.maximum(:iid) }, presence: true

      validates :project, presence: true
      validates :name,
        presence: true,
        uniqueness: { scope: :project_id },
        length: 1..255
      validates :user_xids, feature_flag_user_xids: true

      before_destroy :ensure_no_associated_strategies

      private

      def ensure_no_associated_strategies
        if strategies.present?
          errors.add(:base, 'User list is associated with a strategy')
          throw :abort # rubocop: disable Cop/BanCatchThrow
        end
      end
    end
  end
end
