# frozen_string_literal: true

# Count objects fetched or imported from Github.
module Gitlab
  module GithubImport
    class ObjectCounter
      OPERATIONS = %w[fetched imported].freeze
      PROJECT_COUNTER_LIST_KEY = 'github-importer/object-counters-list/%{project}/%{operation}'
      PROJECT_COUNTER_KEY = 'github-importer/object-counter/%{project}/%{operation}/%{object_type}'

      GLOBAL_COUNTER_KEY = 'github_importer_%{operation}_%{object_type}'
      GLOBAL_COUNTER_DESCRIPTION = 'The number of %{operation} Github %{object_type}'

      CACHING = Gitlab::Cache::Import::Caching

      class << self
        def increment(project, object_type, operation)
          validate_operation!(operation)

          increment_project_counter(project, object_type, operation)
          increment_global_counter(object_type, operation)
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

        # Global counters are long lived, in Prometheus,
        # and it's used to report the health of the Github Importer
        # in the Grafana Dashboard
        # https://dashboards.gitlab.net/d/2zgM_rImz/github-importer?orgId=1
        def increment_global_counter(object_type, operation)
          key = GLOBAL_COUNTER_KEY % {
            operation: operation,
            object_type: object_type
          }
          description = GLOBAL_COUNTER_DESCRIPTION % {
            operation: operation,
            object_type: object_type.to_s.humanize
          }

          Gitlab::Metrics.counter(key.to_sym, description).increment
        end

        # Project counters are short lived, in Redis,
        # and it's used to report how successful a project
        # import was with the #summary method.
        def increment_project_counter(project, object_type, operation)
          counter_key = PROJECT_COUNTER_KEY % { project: project.id, operation: operation, object_type: object_type }

          add_counter_to_list(project, operation, counter_key)

          CACHING.increment(counter_key)
        end

        def add_counter_to_list(project, operation, key)
          CACHING.set_add(counter_list_key(project, operation), key)
        end

        def counter_list_key(project, operation)
          PROJECT_COUNTER_LIST_KEY % { project: project.id, operation: operation }
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
