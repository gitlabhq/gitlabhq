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
          self.inheritance_column = :_type_disabled

          def ensure_stage!(attempts: 2)
            find_stage || create_stage!
          rescue ActiveRecord::RecordNotUnique
            retry if (attempts -= 1) > 0
            raise
          end

          def find_stage
            Stage.find_by(name: self.stage || 'test',
                          pipeline_id: self.commit_id,
                          project_id: self.project_id)
          end

          def create_stage!
            Stage.create!(name: self.stage || 'test',
                          pipeline_id: self.commit_id,
                          project_id: self.project_id)
          end
        end
      end

      def perform(start_id, stop_id)
        stages = Migratable::Build.where('stage_id IS NULL')
          .where('id BETWEEN ? AND ?', start_id, stop_id)
          .map { |build| build.ensure_stage! }
          .compact.map(&:id)

        MigrateBuildStageIdReference.new.perform(start_id, stop_id)
        MigrateStageStatus.new.perform(stages.min, stages.max)
      end
    end
  end
end
