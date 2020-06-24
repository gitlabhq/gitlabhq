# frozen_string_literal: true

module Gitlab
  module Database
    module DynamicModelHelpers
      def define_batchable_model(table_name)
        Class.new(ActiveRecord::Base) do
          include EachBatch

          self.table_name = table_name
          self.inheritance_column = :_type_disabled
        end
      end
    end
  end
end
