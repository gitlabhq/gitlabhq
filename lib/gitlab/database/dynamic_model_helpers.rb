# frozen_string_literal: true

module Gitlab
  module Database
    module DynamicModelHelpers
      BATCH_SIZE = 1_000

      def define_batchable_model(table_name, connection:)
        klass = Class.new(ActiveRecord::Base) do
          include EachBatch

          self.table_name = table_name
          self.inheritance_column = :_type_disabled
        end

        klass.connection = connection
        klass
      end

      def each_batch(table_name, connection:, scope: ->(table) { table.all }, of: BATCH_SIZE)
        if transaction_open?
          raise <<~MSG.squish
            each_batch should not run inside a transaction, you can disable
            transactions by calling disable_ddl_transaction! in the body of
            your migration class
          MSG
        end

        scope.call(define_batchable_model(table_name, connection: connection))
          .each_batch(of: of) { |batch| yield batch }
      end

      def each_batch_range(table_name, connection:, scope: ->(table) { table.all }, of: BATCH_SIZE)
        each_batch(table_name, connection: connection, scope: scope, of: of) do |batch|
          yield batch.pick('MIN(id), MAX(id)')
        end
      end
    end
  end
end
