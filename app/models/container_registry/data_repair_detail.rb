# frozen_string_literal: true

module ContainerRegistry
  class DataRepairDetail < ApplicationRecord
    self.table_name = 'container_registry_data_repair_details'
    self.primary_key = :project_id

    belongs_to :project, optional: false
  end
end
