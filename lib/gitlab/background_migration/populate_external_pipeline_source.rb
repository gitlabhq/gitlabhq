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
        end

        class Build < CommitStatus
        end

        class GenericCommitStatus < CommitStatus
        end
      end

      def perform(start_id, stop_id)
        external_pipelines(start_id, stop_id).each do |pipeline|
          pipeline.update_attribute(:source, Migratable::Pipeline.sources[:external])
        end
      end

      private

      def external_pipelines(start_id, stop_id)
        Migratable::Pipeline.where(id: (start_id..stop_id))
          .where(
            'EXISTS (?) AND NOT EXISTS (?)',
            Migratable::GenericCommitStatus.where("type='CommitStatus'").where('ci_builds.commit_id=ci_pipelines.id').select(1),
            Migratable::Build.where("type='Ci::Build'").where('ci_builds.commit_id=ci_pipelines.id').select(1)
          )
      end
    end
  end
end
