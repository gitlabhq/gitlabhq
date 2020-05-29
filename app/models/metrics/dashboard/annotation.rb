# frozen_string_literal: true

module Metrics
  module Dashboard
    class Annotation < ApplicationRecord
      include DeleteWithLimit

      self.table_name = 'metrics_dashboard_annotations'

      belongs_to :environment, inverse_of: :metrics_dashboard_annotations
      belongs_to :cluster, class_name: 'Clusters::Cluster', inverse_of: :metrics_dashboard_annotations

      validates :starting_at, presence: true
      validates :description, presence: true, length: { maximum: 255 }
      validates :dashboard_path, presence: true, length: { maximum: 255 }
      validates :panel_xid, length: { maximum: 255 }
      validate :single_ownership
      validate :orphaned_annotation
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

        errors.add(:ending_at, s_("Metrics::Dashboard::Annotation|can't be before starting_at time"))
      end

      def single_ownership
        return if cluster.nil? ^ environment.nil?

        errors.add(:base, s_("Metrics::Dashboard::Annotation|Annotation can't belong to both a cluster and an environment at the same time"))
      end

      def orphaned_annotation
        return if cluster.present? || environment.present?

        errors.add(:base, s_("Metrics::Dashboard::Annotation|Annotation must belong to a cluster or an environment"))
      end
    end
  end
end
