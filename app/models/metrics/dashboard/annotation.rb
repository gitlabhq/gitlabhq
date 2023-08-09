# frozen_string_literal: true

module Metrics
  module Dashboard
    class Annotation < ApplicationRecord
      include DeleteWithLimit

      self.table_name = 'metrics_dashboard_annotations'

      validates :starting_at, presence: true
      validates :description, presence: true, length: { maximum: 255 }
      validates :dashboard_path, presence: true, length: { maximum: 255 }
      validates :panel_xid, length: { maximum: 255 }
      validate :ending_at_after_starting_at

      scope :after, ->(after) { where('starting_at >= ?', after) }
      scope :before, ->(before) { where('starting_at <= ?', before) }

      scope :for_dashboard, ->(dashboard_path) { where(dashboard_path: dashboard_path) }
      scope :ending_before, ->(timestamp) { where('COALESCE(ending_at, starting_at) < ?', timestamp) }

      private

      # If annotation has NULL in ending_at column that indicates, that this annotation IS TIED TO SINGLE POINT
      # IN TIME designated by starting_at timestamp. It does NOT mean that annotation is ever going starting from
      # stating_at timestamp
      def ending_at_after_starting_at
        return if ending_at.blank? || starting_at.blank? || starting_at <= ending_at

        errors.add(:ending_at, s_("MetricsDashboardAnnotation|can't be before starting_at time"))
      end
    end
  end
end
