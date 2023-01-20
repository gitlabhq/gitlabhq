# frozen_string_literal: true

# Tracks egress of various services per project
# This class ensures that we keep 1 record per project per month.
module Projects
  class DataTransfer < ApplicationRecord
    self.table_name = 'project_data_transfers'

    belongs_to :project
    belongs_to :namespace

    scope :current_month, -> { where(date: beginning_of_month) }

    def self.beginning_of_month(time = Time.current)
      time.utc.beginning_of_month
    end
  end
end
