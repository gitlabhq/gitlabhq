# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class PopulateExternalPipelineSource
      module Migratable
        class Pipeline < ActiveRecord::Base
          self.table_name = 'ci_pipelines'

          def self.sources
            {
              unknown: nil,
              push: 1,
              web: 2,
              trigger: 3,
              schedule: 4,
              api: 5,
              external: 6
            }
          end
        end

        class CommitStatus < ActiveRecord::Base
          self.table_name = 'ci_builds'
          self.inheritance_column = :_type_disabled

          scope :has_pipeline, -> { where('ci_builds.commit_id=ci_pipelines.id') }
          scope :of_type, -> (type) { where('type=?', type) }
        end
      end

      def perform(start_id, stop_id)
        external_pipelines(start_id, stop_id)
          .update_all(source: Migratable::Pipeline.sources[:external])
      end

      private

      def external_pipelines(start_id, stop_id)
        Migratable::Pipeline.where(id: (start_id..stop_id))
          .where(
            'EXISTS (?) AND NOT EXISTS (?)',
            Migratable::CommitStatus.of_type('GenericCommitStatus').has_pipeline.select(1),
            Migratable::CommitStatus.of_type('Ci::Build').has_pipeline.select(1)
          )
      end
    end
  end
end
