# frozen_string_literal: true
# rubocop:disable Metrics/AbcSize
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class MigrateBuildStage
      def perform(id)
        DatabaseBuild.find_by(id: id).try do |build|
          MigratableStage.new(build).tap do |stage|
            break if stage.exists? || stage.legacy?

            stage.ensure!
            stage.migrate_reference!
            stage.migrate_status!
          end
        end
      end

      class DatabaseStage < ActiveRecord::Base
        self.table_name = 'ci_stages'
      end

      class DatabaseBuild < ActiveRecord::Base
        self.table_name = 'ci_builds'
      end

      class MigratableStage
        def initialize(build)
          @build = build
        end

        def exists?
          @build.reload.stage_id.present?
        end

        ##
        # We can have some very old stages that do not have `ci_builds.stage` set.
        #
        # In that case we just don't migrate such stage.
        #
        def legacy?
         @build.stage.nil?
        end

        def ensure!
          find || create!
        end

        def find
          DatabaseStage.find_by(name: @build.stage,
                                pipeline_id: @build.commit_id,
                                project_id: @build.project_id)
        end

        def create!
          DatabaseStage.create!(name: @build.stage,
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
