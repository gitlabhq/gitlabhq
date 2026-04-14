# frozen_string_literal: true

module Gitlab
  module Database
    module DataIsolation
      module Strategies
        module Arel
          module ActiveRecordExtension
            def arel(*)
              original_arel = super
              return original_arel if Context.disabled?
              return original_arel unless table_has_sharding_key?
              return original_arel unless Gitlab::Database::DataIsolation.configuration.strategy == :arel

              Scope.new.add_scope(original_arel)
            end

            private

            def table_has_sharding_key?
              Gitlab::Database::DataIsolation.configuration.sharding_key_map.key?(klass.table_name)
            end
          end
        end
      end
    end
  end
end
