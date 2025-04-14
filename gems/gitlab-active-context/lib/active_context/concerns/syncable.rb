# frozen_string_literal: true

module ActiveContext
  module Concerns
    module Syncable
      extend ActiveSupport::Concern

      class_methods do
        def sync_with_active_context(on:, using:, condition: nil)
          combined_condition = if condition
                                 -> { syncable? && instance_exec(&condition) }
                               else
                                 -> { syncable? }
                               end

          case on
          when :create then after_create_commit(if: combined_condition, &using)
          when :update then after_update_commit(if: combined_condition, &using)
          when :destroy then after_destroy_commit(if: combined_condition, &using)
          else after_commit(if: combined_condition, &using)
          end
        end
      end

      def syncable?
        raise NotImplementedError
      end
    end
  end
end
