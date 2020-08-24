# frozen_string_literal: true

module Gitlab
  module Ci
    class Lint
      class Result
        attr_reader :jobs, :errors, :warnings

        def initialize(jobs:, errors:, warnings:)
          @jobs = jobs
          @errors = errors
          @warnings = warnings
        end

        def valid?
          @errors.empty?
        end
      end

      def initialize(project:, current_user:)
        @project = project
        @current_user = current_user
      end

      def validate(content, dry_run: false)
        if dry_run && Gitlab::Ci::Features.lint_creates_pipeline_with_dry_run?(@project)
          simulate_pipeline_creation(content)
        else
          static_validation(content)
        end
      end

      private

      def simulate_pipeline_creation(content)
        pipeline = ::Ci::CreatePipelineService
          .new(@project, @current_user, ref: @project.default_branch)
          .execute(:push, dry_run: true, content: content)

        Result.new(
          jobs: dry_run_convert_to_jobs(pipeline.stages),
          errors: pipeline.error_messages.map(&:content),
          warnings: pipeline.warning_messages.map(&:content)
        )
      end

      def static_validation(content)
        result = Gitlab::Ci::YamlProcessor.new_with_validation_errors(
          content,
          project: @project,
          user: @current_user,
          sha: @project.repository.commit.sha)

        Result.new(
          jobs: static_validation_convert_to_jobs(result.config&.stages, result.config&.builds),
          errors: result.errors,
          warnings: result.warnings
        )
      end

      def dry_run_convert_to_jobs(stages)
        stages.reduce([]) do |jobs, stage|
          jobs + stage.statuses.map do |job|
            {
              name: job.name,
              stage: stage.name,
              before_script: job.options[:before_script],
              script: job.options[:script],
              after_script: job.options[:after_script],
              tag_list: (job.tag_list if job.is_a?(::Ci::Build)),
              environment: job.options.dig(:environment, :name),
              when: job.when,
              allow_failure: job.allow_failure
            }
          end
        end
      end

      def static_validation_convert_to_jobs(stages, all_jobs)
        jobs = []
        return jobs unless stages || all_jobs

        stages.each do |stage_name|
          all_jobs.each do |job|
            next unless job[:stage] == stage_name

            jobs << {
              name: job[:name],
              stage: stage_name,
              before_script: job.dig(:options, :before_script),
              script: job.dig(:options, :script),
              after_script: job.dig(:options, :after_script),
              tag_list: job[:tag_list].to_a,
              only: job[:only],
              except: job[:except],
              environment: job[:environment],
              when: job[:when],
              allow_failure: job[:allow_failure]
            }
          end
        end

        jobs
      end
    end
  end
end
