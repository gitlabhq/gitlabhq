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
  #
  module Partitionable
    extend ActiveSupport::Concern
    include ::Gitlab::Utils::StrongMemoize

    included do
      before_validation :set_partition_id, on: :create
      validates :partition_id, presence: true

      def set_partition_id
        return unless partition_scope_record

        self.partition_id = partition_scope_record.partition_id
      end
    end

    class_methods do
      private

      def partitionable(scope:)
        define_method(:partition_scope_record) do
          strong_memoize(:partition_scope_record) do
            scope.to_proc.call(self)
          end
        end
      end
    end
  end
end
