# frozen_string_literal: true

# Caches loading of additional types from the DB
# https://github.com/rails/rails/blob/v7.1.3.4/activerecord/lib/active_record/connection_adapters/postgresql_adapter.rb#L997

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

            # Clone the cached type map's internal mapping so each connection gets its own copy. This prevents
            # `type_map.clear` on one connection (during reload_type_map) from emptying the map for all other
            # connections sharing the cache. See https://gitlab.com/gitlab-org/gitlab/-/issues/592511
            if cached_type_map
              mapping_copy = cached_type_map.instance_variable_get(:@mapping).dup
              map.instance_variable_set(:@mapping, mapping_copy)

              break
            end

            super
            self.class.type_map_cache[@connection_parameters.hash] = map
          end
        end

        def reload_type_map
          # This method is also called when a connection is initialized.
          # We only want to clear the cache when @type_map is present and we are actually reloading.
          if @type_map
            TYPE_MAP_CACHE_MONITOR.synchronize do
              self.class.type_map_cache[@connection_parameters.hash] = nil
            end
          end

          super
        end
      end
    end
  end
end
