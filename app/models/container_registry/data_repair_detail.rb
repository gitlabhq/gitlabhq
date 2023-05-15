# frozen_string_literal: true

module ContainerRegistry
  class DataRepairDetail < ApplicationRecord
    include EachBatch

    self.table_name = 'container_registry_data_repair_details'
    self.primary_key = :project_id

    belongs_to :project, optional: false

    enum status: { ongoing: 0, completed: 1, failed: 2 }

    scope :ongoing_since, ->(threshold) { where(status: :ongoing).where('updated_at < ?', threshold) }
  end
end
