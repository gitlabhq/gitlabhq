# frozen_string_literal: true

# Count objects fetched or imported from Github.
module Gitlab
  module GithubImport
    class ObjectCounter
      OPERATIONS = %w[fetched imported].freeze
      PROJECT_COUNTER_LIST_KEY = 'github-importer/object-counters-list/%{project}/%{operation}'
      PROJECT_COUNTER_KEY = 'github-importer/object-counter/%{project}/%{operation}/%{object_type}'
      EMPTY_SUMMARY = OPERATIONS.index_with { |operation| {} }

      GLOBAL_COUNTER_KEY = 'github_importer_%{operation}_%{object_type}'
      GLOBAL_COUNTER_DESCRIPTION = 'The number of %{operation} Github %{object_type}'

      CACHING = Gitlab::Cache::Import::Caching

      IMPORT_CACHING_TIMEOUT = 2.weeks.to_i

      class << self
        # Increments the project and the global counters if the given value is >= 1
        def increment(project, object_type, operation, value: 1)
          integer = value.to_i

          return if integer <= 0

          validate_operation!(operation)

          increment_project_counter(project, object_type, operation, integer)
          increment_global_counter(object_type, operation, integer)

          project.import_state&.expire_etag_cache
        end

        def summary(project)
          cached_summary = cashed_summary(project)
          # Actual information about objects that have already been imported is stored
          # in the Redis Cache until Redis key is expired.
          # After import is completed we store this information in project's import_checksums
          return cached_summary if cached_summary != EMPTY_SUMMARY || project.import_state.blank?

          project.import_state.completed? ? project.import_checksums : cached_summary
        end

        private

        def cashed_summary(project)
          OPERATIONS.each_with_object({}) do |operation, result|
            result[operation] = {}

            CACHING
              .values_from_set(counter_list_key(project, operation))
              .sort
              .each do |counter|
                object_type = counter.split('/').last
                result[operation][object_type] = CACHING.read_integer(counter, timeout: IMPORT_CACHING_TIMEOUT) || 0
              end
          end
        end

        # Global counters are long lived, in Prometheus,
        # and it's used to report the health of the Github Importer
        # in the Grafana Dashboard
        # https://dashboards.gitlab.net/d/2zgM_rImz/github-importer?orgId=1
        def increment_global_counter(object_type, operation, value)
          key = GLOBAL_COUNTER_KEY % {
            operation: operation,
            object_type: object_type
          }
          description = GLOBAL_COUNTER_DESCRIPTION % {
            operation: operation,
            object_type: object_type.to_s.humanize
          }

          Gitlab::Metrics.counter(key.to_sym, description).increment(by: value)
        end

        # Project counters are short lived, in Redis,
        # and it's used to report how successful a project
        # import was with the #summary method.
        def increment_project_counter(project, object_type, operation, value)
          counter_key = PROJECT_COUNTER_KEY % {
            project: project.id,
            operation: operation,
            object_type: object_type
          }

          add_counter_to_list(project, operation, counter_key)

          CACHING.increment_by(counter_key, value, timeout: IMPORT_CACHING_TIMEOUT)
        end

        def add_counter_to_list(project, operation, key)
          CACHING.set_add(counter_list_key(project, operation), key, timeout: IMPORT_CACHING_TIMEOUT)
        end

        def counter_list_key(project, operation)
          PROJECT_COUNTER_LIST_KEY % { project: project.id, operation: operation }
        end

        def validate_operation!(operation)
          unless operation.to_s.presence_in(OPERATIONS)
            raise ArgumentError, "operation must be #{OPERATIONS.join(' or ')}"
          end
        end
      end
    end
  end
end
