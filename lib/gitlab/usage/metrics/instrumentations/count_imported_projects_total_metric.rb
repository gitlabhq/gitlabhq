# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountImportedProjectsTotalMetric < DatabaseMetric
          # Relation and operation are not used, but are included to satisfy expectations
          # of other metric generation logic.
          relation { Project }
          operation :count

          IMPORT_TYPES = %w[gitlab_project gitlab github bitbucket bitbucket_server gitea git manifest
                            gitlab_migration].freeze

          def value
            count(project_relation) + count(entity_relation)
          end

          def to_sql
            project_relation_sql = Gitlab::Usage::Metrics::Query.for(:count, project_relation)
            entity_relation_sql = Gitlab::Usage::Metrics::Query.for(:count, entity_relation)

            "SELECT (#{project_relation_sql}) + (#{entity_relation_sql})"
          end

          private

          def project_relation
            Project.imported_from(IMPORT_TYPES).where(time_constraints)
          end

          def entity_relation
            BulkImports::Entity.where(source_type: :project_entity).where(time_constraints)
          end
        end
      end
    end
  end
end
