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
            break @type_map = cached_type_map if cached_type_map

            super
            self.class.type_map_cache[@connection_parameters.hash] = map
          end
        end

        def reload_type_map
          if ::Gitlab.next_rails? && @type_map.blank?
            @type_map = ActiveRecord::Type::HashLookupTypeMap.new

            return initialize_type_map
          end

          TYPE_MAP_CACHE_MONITOR.synchronize do
            self.class.type_map_cache[@connection_parameters.hash] = nil
          end

          super
        end
      end
    end
  end
end
