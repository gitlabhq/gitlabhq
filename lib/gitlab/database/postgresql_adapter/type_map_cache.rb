# frozen_string_literal: true

# Caches loading of additional types from the DB
# https://github.com/rails/rails/blob/v6.0.3.2/activerecord/lib/active_record/connection_adapters/postgresql_adapter.rb#L521-L589

# rubocop:disable Gitlab/ModuleWithInstanceVariables

module Gitlab
  module Database
    module PostgresqlAdapter
      module TypeMapCache
        extend ActiveSupport::Concern

        TYPE_MAP_CACHE_MONITOR = ::Monitor.new

        class_methods do
          def type_map_cache
            TYPE_MAP_CACHE_MONITOR.synchronize do
              @type_map_cache ||= {}
            end
          end
        end

        def initialize_type_map(map = type_map)
          TYPE_MAP_CACHE_MONITOR.synchronize do
            cached_type_map = self.class.type_map_cache[@connection_parameters.hash]
            break @type_map = cached_type_map if cached_type_map

            super
            self.class.type_map_cache[@connection_parameters.hash] = map
          end
        end

        def reload_type_map
          TYPE_MAP_CACHE_MONITOR.synchronize do
            self.class.type_map_cache[@connection_parameters.hash] = nil
          end

          super
        end
      end
    end
  end
end
