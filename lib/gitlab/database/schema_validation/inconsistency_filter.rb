# frozen_string_literal: true

module Gitlab
  module Database
    module SchemaValidation
      class InconsistencyFilter
        def initialize(tables, triggers)
          @tables = tables
          @triggers = triggers
        end

        def to_proc
          proc do |inconsistency|
            inconsistency unless ignored?(inconsistency)
          end
        end

        private

        attr_reader :tables, :triggers

        def ignored?(inconsistency)
          case inconsistency.type
          in 'extra_tables' | 'missing_tables'
            ignored_table?(inconsistency.table_name)
          in 'extra_triggers' | 'missing_triggers'
            ignored_trigger?(inconsistency.object_name)
          else
            false
          end
        end

        def ignored_table?(name)
          tables.include?(name)
        end

        def ignored_trigger?(name)
          triggers.any? { |ignored_object| name.to_s.include?(ignored_object) }
        end
      end
    end
  end
end
