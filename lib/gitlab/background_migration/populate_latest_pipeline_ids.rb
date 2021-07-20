# frozen_string_literal: true

# rubocop: disable Style/Documentation
module Gitlab
  module BackgroundMigration
    class PopulateLatestPipelineIds
      class ProjectSetting < ActiveRecord::Base
        include EachBatch

        self.table_name = 'project_settings'

        scope :in_range, -> (start_id, end_id) { where(id: start_id..end_id) }
        scope :has_vulnerabilities_without_latest_pipeline_set, -> do
          joins('LEFT OUTER JOIN vulnerability_statistics vs ON vs.project_id = project_settings.project_id')
            .where(vs: { latest_pipeline_id: nil })
            .where('has_vulnerabilities IS TRUE')
        end
      end

      def perform(start_id, end_id)
        # no-op
      end
    end
  end
end

Gitlab::BackgroundMigration::PopulateLatestPipelineIds.prepend_mod
