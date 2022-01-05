# frozen_string_literal: true

module Types
  module Ci
    class RunnerType < BaseObject
      edge_type_class(RunnerWebUrlEdge)
      graphql_name 'CiRunner'
      authorize :read_runner
      present_using ::Ci::RunnerPresenter

      expose_permissions Types::PermissionTypes::Ci::Runner

      JOB_COUNT_LIMIT = 1000

      alias_method :runner, :object

      field :id, ::Types::GlobalIDType[::Ci::Runner], null: false,
            description: 'ID of the runner.'
      field :description, GraphQL::Types::String, null: true,
            description: 'Description of the runner.'
      field :created_at, Types::TimeType, null: true,
            description: 'Timestamp of creation of this runner.'
      field :contacted_at, Types::TimeType, null: true,
            description: 'Timestamp of last contact from this runner.',
            method: :contacted_at
      field :maximum_timeout, GraphQL::Types::Int, null: true,
            description: 'Maximum timeout (in seconds) for jobs processed by the runner.'
      field :access_level, ::Types::Ci::RunnerAccessLevelEnum, null: false,
            description: 'Access level of the runner.'
      field :active, GraphQL::Types::Boolean, null: false,
            description: 'Indicates the runner is allowed to receive jobs.'
      field :status,
            Types::Ci::RunnerStatusEnum,
            null: false,
            description: 'Status of the runner.',
            resolver: ::Resolvers::Ci::RunnerStatusResolver
      field :version, GraphQL::Types::String, null: true,
            description: 'Version of the runner.'
      field :short_sha, GraphQL::Types::String, null: true,
            description: %q(First eight characters of the runner's token used to authenticate new job requests. Used as the runner's unique ID.)
      field :revision, GraphQL::Types::String, null: true,
            description: 'Revision of the runner.'
      field :locked, GraphQL::Types::Boolean, null: true,
            description: 'Indicates the runner is locked.'
      field :run_untagged, GraphQL::Types::Boolean, null: false,
            description: 'Indicates the runner is able to run untagged jobs.'
      field :ip_address, GraphQL::Types::String, null: true,
            description: 'IP address of the runner.'
      field :runner_type, ::Types::Ci::RunnerTypeEnum, null: false,
            description: 'Type of the runner.'
      field :tag_list, [GraphQL::Types::String], null: true,
            description: 'Tags associated with the runner.'
      field :project_count, GraphQL::Types::Int, null: true,
            description: 'Number of projects that the runner is associated with.'
      field :job_count, GraphQL::Types::Int, null: true,
            description: "Number of jobs processed by the runner (limited to #{JOB_COUNT_LIMIT}, plus one to indicate that more items exist)."
      field :admin_url, GraphQL::Types::String, null: true,
            description: 'Admin URL of the runner. Only available for administrators.'
      field :executor_name, GraphQL::Types::String, null: true,
            description: 'Executor last advertised by the runner.',
            method: :executor_name,
            feature_flag: :graphql_ci_runner_executor

      def job_count
        # We limit to 1 above the JOB_COUNT_LIMIT to indicate that more items exist after JOB_COUNT_LIMIT
        runner.builds.limit(JOB_COUNT_LIMIT + 1).count
      end

      def admin_url
        Gitlab::Routing.url_helpers.admin_runner_url(runner) if can_admin_runners?
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def project_count
        BatchLoader::GraphQL.for(runner.id).batch(key: :runner_project_count) do |ids, loader, args|
          counts = ::Ci::Runner.project_type
            .select(:id, 'COUNT(ci_runner_projects.id) as count')
            .left_outer_joins(:runner_projects)
            .where(id: ids)
            .group(:id)
            .index_by(&:id)

          ids.each do |id|
            loader.call(id, counts[id]&.count)
          end
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      private

      def can_admin_runners?
        context[:current_user]&.can_admin_all_resources?
      end
    end
  end
end

Types::Ci::RunnerType.prepend_mod_with('Types::Ci::RunnerType')
