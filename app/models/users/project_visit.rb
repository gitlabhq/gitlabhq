# frozen_string_literal: true

module Users
  class ProjectVisit < ApplicationRecord
    include Users::Visitable
    include PartitionedTable

    self.table_name = "projects_visits"
    self.primary_key = :id

    partitioned_by :visited_at, strategy: :monthly, retain_for: 3.months

    validates :entity_id, presence: true
    validates :user_id, presence: true
    validates :visited_at, presence: true
  end
end
