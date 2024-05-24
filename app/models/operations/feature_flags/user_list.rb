# frozen_string_literal: true

module Operations
  module FeatureFlags
    class UserList < ApplicationRecord
      include AtomicInternalId
      include IidRoutes
      include ::Gitlab::SQL::Pattern

      self.table_name = 'operations_user_lists'

      belongs_to :project
      has_many :strategy_user_lists
      has_many :strategies, through: :strategy_user_lists

      has_internal_id :iid, scope: :project, presence: true

      validates :project, presence: true
      validates :name,
        presence: true,
        uniqueness: { scope: :project_id },
        length: 1..255
      validates :user_xids, feature_flag_user_xids: true

      before_destroy :ensure_no_associated_strategies

      scope :for_name_like, ->(query) do
        fuzzy_search(query, [:name], use_minimum_char_limit: false)
      end

      def self.belongs_to?(project_id, user_list_ids)
        uniq_ids = user_list_ids.uniq
        where(id: uniq_ids, project_id: project_id).count == uniq_ids.count
      end

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
