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

      authorize :create_pipeline

      argument :project_path, GraphQL::Types::ID,
        required: true,
        description: 'Project of the CI config.'

      argument :sha, GraphQL::Types::String,
        required: false,
        description: "Sha for the pipeline."

      argument :content, GraphQL::Types::String,
        required: true,
        description: "Contents of `.gitlab-ci.yml`."

      argument :dry_run, GraphQL::Types::Boolean,
        required: false,
        description: 'Run pipeline creation simulation, or only do static check.'

      argument :skip_verify_project_sha, GraphQL::Types::Boolean,
        required: false,
        experiment: { milestone: '16.5' },
        description: "If the provided `sha` is found in the project's repository but is not " \
          "associated with a Git reference (a detached commit), the verification fails and a " \
          "validation error is returned. Otherwise, verification passes, even if the `sha` is " \
          "invalid. Set to `true` to skip this verification process."

      def resolve(project_path:, content:, sha: nil, dry_run: false, skip_verify_project_sha: false)
        project = authorized_find!(project_path: project_path)

        result = ::Gitlab::Ci::Lint
          .new(project: project, current_user: context[:current_user], sha: sha,
            verify_project_sha: !skip_verify_project_sha)
          .validate(content, dry_run: dry_run)

        response(result)
      rescue GRPC::InvalidArgument => e
        Gitlab::ErrorTracking.track_and_raise_exception(e, sha: sha)
      end

      private

      def response(result)
        {
          status: result.status,
          errors: result.errors,
          warnings: result.warnings,
          stages: make_stages(result),
          merged_yaml: result.merged_yaml,
          includes: result.includes
        }
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

      def make_stages(result)
        return [] unless result.valid?

        make_groups(result.jobs)
          .group_by { |group| group[:stage] }
          .map { |name, groups| { name: name, groups: groups } }
      end

      def find_object(project_path:)
        resolve_project(full_path: project_path)
      end
    end
  end
end
