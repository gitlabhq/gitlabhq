# frozen_string_literal: true
# rubocop:disable Metrics/AbcSize
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class MigrateBuildStage
      def perform(id)
        Ci::Build.find_by(id: id).try do |build|
          Stage.new(build).tap do |stage|
            return if stage.exists?

            stage.ensure!
            stage.migrate_reference!
            stage.migrate_status!
          end
        end
      end

      private

      class Ci::Stage < ActiveRecord::Base
        self.table_name = 'ci_stages'
      end

      class Ci::Build < ActiveRecord::Base
        self.table_name = 'ci_builds'
      end

      class Stage
        def initialize(build)
          @build = build
        end

        def exists?
          @build.reload.stage_id.present?
        end

        def ensure!
          find || create!
        end

        def find
          Ci::Stage.find_by(name: @build.stage,
                            pipeline_id: @build.commit_id,
                            project_id: @build.project_id)
        end

        def create!
          Ci::Stage.create!(name: @build.stage,
                            pipeline_id: @build.commit_id,
                            project_id: @build.project_id)
        end

        def migrate_reference!
          MigrateBuildStageIdReference.new.perform(@build.id, @build.id)
        end

        def migrate_status!
          raise ArgumentError unless exists?

          MigrateStageStatus.new.perform(@build.stage_id, @build.stage_id)
        end
      end
    end
  end
end
