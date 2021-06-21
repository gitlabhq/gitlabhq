# frozen_string_literal: true

# Count objects fetched or imported from Github in the context of the
# project being imported.
module Gitlab
  module GithubImport
    class ObjectCounter
      OPERATIONS = %w[fetched imported].freeze
      COUNTER_LIST_KEY = 'github-importer/object-counters-list/%{project}/%{operation}'
      COUNTER_KEY = 'github-importer/object-counter/%{project}/%{operation}/%{object_type}'
      CACHING = Gitlab::Cache::Import::Caching

      class << self
        def increment(project, object_type, operation)
          validate_operation!(operation)

          counter_key = COUNTER_KEY % { project: project.id, operation: operation, object_type: object_type }

          add_counter_to_list(project, operation, counter_key)

          CACHING.increment(counter_key)
        end

        def summary(project)
          OPERATIONS.each_with_object({}) do |operation, result|
            result[operation] = {}

            CACHING
              .values_from_set(counter_list_key(project, operation))
              .sort
              .each do |counter|
                object_type = counter.split('/').last
                result[operation][object_type] = CACHING.read_integer(counter)
              end
          end
        end

        private

        def add_counter_to_list(project, operation, key)
          CACHING.set_add(counter_list_key(project, operation), key)
        end

        def counter_list_key(project, operation)
          COUNTER_LIST_KEY % { project: project.id, operation: operation }
        end

        def validate_operation!(operation)
          unless operation.to_s.presence_in(OPERATIONS)
            raise ArgumentError, "Operation must be #{OPERATIONS.join(' or ')}"
          end
        end
      end
    end
  end
end
