# frozen_string_literal: true

module Users
  class GroupVisit < ApplicationRecord
    include Users::Visitable
    include PartitionedTable

    self.table_name = "groups_visits"
    self.primary_key = :id

    partitioned_by :visited_at, strategy: :monthly, retain_for: 3.months

    validates :entity_id, presence: true
    validates :user_id, presence: true
    validates :visited_at, presence: true

    MAX_FRECENT_ITEMS = 3

    def self.frecent_groups(user_id:)
      ids = frecent_visits_scores(user_id: user_id, limit: MAX_FRECENT_ITEMS).pluck("entity_id")
      Group.find(ids)
    end
  end
end
