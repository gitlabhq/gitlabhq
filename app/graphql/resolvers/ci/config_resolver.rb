# frozen_string_literal: true

module Resolvers
  module Ci
    class ConfigResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource
      include ResolvesProject

      type Types::Ci::Config::ConfigType, null: true
      description <<~MD
        Linted and processed contents of a CI config.
        Should not be requested more than once per request.
      MD

      authorize :read_pipeline

      argument :project_path, GraphQL::Types::ID,
               required: true,
               description: 'The project of the CI config.'

      argument :sha, GraphQL::Types::String,
               required: false,
               description: "Sha for the pipeline."

      argument :content, GraphQL::Types::String,
               required: true,
               description: "Contents of `.gitlab-ci.yml`."

      argument :dry_run, GraphQL::Types::Boolean,
               required: false,
               description: 'Run pipeline creation simulation, or only do static check.'

      def resolve(project_path:, content:, sha: nil, dry_run: false)
        project = authorized_find!(project_path: project_path)

        result = ::Gitlab::Ci::Lint
          .new(project: project, current_user: context[:current_user], sha: sha)
          .validate(content, dry_run: dry_run)

        response(result).merge(merged_yaml: result.merged_yaml)
      end

      private

      def response(result)
        if result.errors.empty?
          {
            status: :valid,
            errors: [],
            stages: make_stages(result.jobs)
          }
        else
          {
            status: :invalid,
            errors: result.errors
          }
        end
      end

      def make_jobs(config_jobs)
        config_jobs.map do |job|
          {
            name: job[:name],
            stage: job[:stage],
            group_name: CommitStatus.new(name: job[:name]).group_name,
            needs: job[:needs] || [],
            allow_failure: job[:allow_failure],
            before_script: job[:before_script],
            script: job[:script],
            after_script: job[:after_script],
            only: job[:only],
            except: job[:except],
            when: job[:when],
            tags: job[:tag_list],
            environment: job[:environment]
          }
        end
      end

      def make_groups(job_data)
        jobs = make_jobs(job_data)

        jobs_by_group = jobs.group_by { |job| job[:group_name] }
        jobs_by_group.map do |name, jobs|
          { jobs: jobs, name: name, stage: jobs.first[:stage], size: jobs.size }
        end
      end

      def make_stages(jobs)
        make_groups(jobs)
          .group_by { |group| group[:stage] }
          .map { |name, groups| { name: name, groups: groups } }
      end

      def find_object(project_path:)
        resolve_project(full_path: project_path)
      end
    end
  end
end
