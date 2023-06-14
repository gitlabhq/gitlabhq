# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountSnippetsMetric < DatabaseMetric
          operation :count
          # Relation and operation are not used, but are included to satisfy expectations
          # of other metric generation logic.
          relation { Snippet }

          def value
            count(project_snippet_relation) + count(personal_snippet_relation)
          end

          def project_snippet_relation
            ProjectSnippet.where(time_constraints)
          end

          def personal_snippet_relation
            PersonalSnippet.where(time_constraints)
          end

          def to_sql
            project_snippet_relation_sql = Gitlab::Usage::Metrics::Query.for(:count, project_snippet_relation)
            personal_snippet_relation_sql = Gitlab::Usage::Metrics::Query.for(:count, personal_snippet_relation)

            "SELECT (#{project_snippet_relation_sql}) + (#{personal_snippet_relation_sql})"
          end
        end
      end
    end
  end
end
