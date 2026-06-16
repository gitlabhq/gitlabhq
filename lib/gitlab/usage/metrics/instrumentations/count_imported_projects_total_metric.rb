# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountImportedProjectsTotalMetric < DatabaseMetric
          operation :count

          IMPORT_TYPES = %w[gitlab_project github bitbucket bitbucket_server gitea git manifest
            gitlab_project_migration fogbugz].freeze

          relation { Project.imported_from(IMPORT_TYPES) }
        end
      end
    end
  end
end
