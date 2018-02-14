# frozen_string_literal: true
# rubocop:disable Metrics/AbcSize
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class MigrateBuildStage
      module Migratable
        class Stage < ActiveRecord::Base
          self.table_name = 'ci_stages'
        end

        class Build < ActiveRecord::Base
          self.table_name = 'ci_builds'

          def ensure_stage!
            find || create!
          rescue ActiveRecord::RecordNotUnique
            # TODO
          end

          def find
            Stage.find_by(name: self.stage,
                          pipeline_id: self.commit_id,
                          project_id: self.project_id)
          end

          def create!
            Stage.create!(name: self.stage || 'test',
                          pipeline_id: self.commit_id,
                          project_id: self.project_id)
          end
        end
      end

      def perform(start_id, stop_id)
        # TODO, should we disable_statement_timeout?
        # TODO, use plain SQL query?

        stages = Migratable::Build.where('stage_id IS NULL')
          .where("id BETWEEN #{start_id.to_i} AND #{stop_id.to_i}")
          .map { |build| build.ensure_stage! }
          .compact.map(&:id)

        MigrateBuildStageIdReference.new.perform(start_id, stop_id)
        MigrateStageStatus.new.perform(stages.min, stages.max)
      end
    end
  end
end
