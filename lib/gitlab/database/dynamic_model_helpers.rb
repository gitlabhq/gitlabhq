# frozen_string_literal: true

module Gitlab
  module Database
    module DynamicModelHelpers
      BATCH_SIZE = 1_000

      def define_batchable_model(table_name, connection:, primary_key: nil, base_class: ActiveRecord::Base)
        klass = Class.new(base_class) do
          include EachBatch

          self.table_name = table_name
          self.inheritance_column = :_type_disabled
        end

        klass.primary_key = primary_key if connection.primary_keys(table_name).length > 1
        klass.connection = connection
        klass
      end

      def each_batch(table_name, connection:, scope: ->(table) { table.all }, of: BATCH_SIZE, **opts)
        if transaction_open?
          raise <<~MSG.squish
            each_batch should not run inside a transaction, you can disable
            transactions by calling disable_ddl_transaction! in the body of
            your migration class
          MSG
        end

        opts.select! { |k, _| [:column].include? k }

        batchable_model = define_batchable_model(table_name, connection: connection)

        scope.call(batchable_model)
          .each_batch(of: of, **opts) { |batch| yield batch, batchable_model }
      end

      def each_batch_range(table_name, connection:, scope: ->(table) { table.all }, of: BATCH_SIZE, **opts)
        opts.select! { |k, _| [:column].include? k }

        each_batch(table_name, connection: connection, scope: scope, of: of, **opts) do |batch, batchable_model|
          column = opts.fetch(:column, batchable_model.primary_key)

          yield batch.pick("MIN(#{column}), MAX(#{column})")
        end
      end
    end
  end
end
