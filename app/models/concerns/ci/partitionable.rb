# frozen_string_literal: true

module Ci
  ##
  # This module implements a way to set the `partion_id` value on a dependent
  # resource from a parent record.
  # Usage:
  #
  #     class PipelineVariable < Ci::ApplicationRecord
  #       include Ci::Partitionable
  #
  #       belongs_to :pipeline
  #       partitionable scope: :pipeline
  #       # Or
  #       partitionable scope: ->(record) { record.partition_value }
  #
  #
  module Partitionable
    extend ActiveSupport::Concern
    include ::Gitlab::Utils::StrongMemoize

    included do
      before_validation :set_partition_id, on: :create
      validates :partition_id, presence: true

      def set_partition_id
        return if partition_id_changed? && partition_id.present?
        return unless partition_scope_value

        self.partition_id = partition_scope_value
      end
    end

    class_methods do
      private

      def partitionable(scope:)
        define_method(:partition_scope_value) do
          strong_memoize(:partition_scope_value) do
            record = scope.to_proc.call(self)
            record.respond_to?(:partition_id) ? record.partition_id : record
          end
        end
      end
    end
  end
end
