# frozen_string_literal: true

module Mutations
  module Ci
    class Lint < BaseMutation
      graphql_name 'CiLint'

      description <<~MD
        Linted and processed contents of a CI config.
        Should not be requested more than once per request.
      MD

      include Gitlab::Graphql::Authorize::AuthorizeResource
      include ResolvesProject

      authorize :create_pipeline

      argument :project_path, GraphQL::Types::ID,
        required: true,
        description: 'Project of the CI config.'

      argument :content, GraphQL::Types::String,
        required: true,
        description: "Contents of `.gitlab-ci.yml`."

      argument :ref, GraphQL::Types::String,
        required: false,
        description: 'Ref to use when linting. Default is the project default branch.'

      argument :dry_run, GraphQL::Types::Boolean,
        required: false,
        description: 'Run pipeline creation simulation, or only do static check.'

      field :config, Types::Ci::Config::ConfigType, null: true, description: 'Linted CI config and metadata.'

      def resolve(project_path:, content:, ref: nil, dry_run: false)
        project = authorized_find!(project_path: project_path)
        ref ||= project.default_branch

        return feature_unfinished_error unless Feature.enabled?(:ci_lint_mutation, project)

        result = ::Gitlab::Ci::Lint
          .new(project: project, current_user: context[:current_user])
          .validate(content, dry_run: dry_run, ref: ref)

        {
          config: response(result),
          errors: []
        }
      rescue GRPC::InvalidArgument => e
        Gitlab::ErrorTracking.track_and_raise_exception(e, ref: ref)
      end

      private

      def feature_unfinished_error
        unfinished_error = "This mutation is unfinished and not yet available for use. " \
          "Track its progress in https://gitlab.com/gitlab-org/gitlab/-/issues/540764."

        {
          config: nil,
          errors: [unfinished_error]
        }
      end

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
            group_name: Gitlab::Utils::Job.group_name(job[:name]),
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
