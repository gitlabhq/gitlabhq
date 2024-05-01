# frozen_string_literal: true

# Tracks egress of various services per project
# This class ensures that we keep 1 record per project per month.
module Projects
  class DataTransfer < ApplicationRecord
    include CounterAttribute

    self.table_name = 'project_data_transfers'

    belongs_to :project
    belongs_to :namespace

    scope :current_month, -> { where(date: beginning_of_month) }
    scope :with_project_between_dates, ->(project, from, to) {
      where(project: project, date: from..to)
    }
    scope :with_namespace_between_dates, ->(namespace, from, to) {
      where(namespace: namespace, date: from..to)
        .group(:date, :namespace_id)
        .order(date: :desc)
    }

    counter_attribute :repository_egress, returns_current: true
    counter_attribute :artifacts_egress, returns_current: true
    counter_attribute :packages_egress, returns_current: true
    counter_attribute :registry_egress, returns_current: true

    def self.beginning_of_month(time = Time.current)
      time.utc.beginning_of_month
    end
  end
end
