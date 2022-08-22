# frozen_string_literal: true

module Gitlab
  module Seeders
    module Ci
      class DailyBuildGroupReportResult
        DEFAULT_BRANCH = 'master'
        COUNT_OF_DAYS = 5

        def initialize(project)
          @project = project
          @last_pipeline = project.last_pipeline
        end

        def seed
          COUNT_OF_DAYS.times do |count|
            date = Time.now.utc - count.day
            create_report(date)
          end
        end

        private

        attr_reader :project, :last_pipeline

        def create_report(date)
          last_pipeline.builds.uniq(&:group_name).each do |build|
            ::Ci::DailyBuildGroupReportResult.create(
              project: project,
              last_pipeline: last_pipeline,
              date: date,
              ref_path: last_pipeline.source_ref_path,
              group_name: build.group_name,
              data: {
                'coverage' => rand(20..99)
              },
              group: project.group,
              default_branch: last_pipeline.default_branch?
            )
          rescue ActiveRecord::RecordNotUnique
            return false
          end
        end
      end
    end
  end
end
