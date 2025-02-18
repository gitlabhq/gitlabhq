# frozen_string_literal: true

module Types
  module Ci
    class RunnerType < BaseObject
      graphql_name 'CiRunner'

      edge_type_class(RunnerWebUrlEdge)
      connection_type_class RunnerCountableConnectionType

      authorize :read_runner
      present_using ::Ci::RunnerPresenter
      expose_permissions Types::PermissionTypes::Ci::Runner

      JOB_COUNT_LIMIT = 1000

      alias_method :runner, :object

      field :access_level, ::Types::Ci::RunnerAccessLevelEnum, null: false,
        description: 'Access level of the runner.'
      field :active, GraphQL::Types::Boolean, null: false,
        description: 'Indicates the runner is allowed to receive jobs.',
        deprecated: { reason: 'Use paused', milestone: '14.8' }
      field :admin_url, GraphQL::Types::String, null: true,
        description: 'Admin URL of the runner. Only available for administrators.'
      field :contacted_at, Types::TimeType, null: true,
        description: 'Timestamp of last contact from the runner.'
      field :created_at, Types::TimeType, null: true,
        description: 'Timestamp of creation of the runner.'
      field :created_by, Types::UserType, null: true,
        description: 'User that created the runner.',
        method: :creator
      field :creation_method, Types::Ci::RunnerCreationMethodEnum, null: true,
        method: :registration_type,
        description: 'Type of runner registration.',
        experiment: { milestone: '17.0' }
      field :description, GraphQL::Types::String, null: true,
        description: 'Description of the runner.'
      field :edit_admin_url, GraphQL::Types::String, null: true,
        description: 'Admin form URL of the runner. Only available for administrators.'
      field :ephemeral_authentication_token, GraphQL::Types::String, null: true,
        description: 'Ephemeral authentication token used for runner manager registration. Only available for the creator of the runner for a limited time during registration.',
        authorize: :read_ephemeral_token,
        experiment: { milestone: '15.9' }
      field :ephemeral_register_url, GraphQL::Types::String, null: true,
        description: 'URL of the registration page of the runner manager. Only available for the creator of the runner for a limited time during registration.',
        experiment: { milestone: '15.11' }
      field :groups, null: true,
        resolver: ::Resolvers::Ci::RunnerGroupsResolver,
        description: 'Groups the runner is associated with. For group runners only.'
      field :id, ::Types::GlobalIDType[::Ci::Runner], null: false, description: 'ID of the runner.'
      field :job_count, GraphQL::Types::Int, null: true,
        description: "Number of jobs processed by the runner (limited to #{JOB_COUNT_LIMIT}, plus one to " \
          "indicate that more items exist).\n`jobCount` is an optimized version of `jobs { count }`, " \
          "and can be requested for multiple runners on the same request.",
        resolver: ::Resolvers::Ci::RunnerJobCountResolver
      field :job_execution_status,
        Types::Ci::RunnerJobExecutionStatusEnum,
        null: true,
        description: 'Job execution status of the runner.',
        experiment: { milestone: '15.7' }
      field :jobs, ::Types::Ci::JobType.connection_type, null: true,
        description: 'Jobs assigned to the runner. This field can only be resolved for one runner in any single request.',
        authorize: :read_builds,
        resolver: ::Resolvers::Ci::RunnerJobsResolver
      field :locked, GraphQL::Types::Boolean, null: true,
        description: 'Indicates the runner is locked.'
      field :maintenance_note, GraphQL::Types::String, null: true,
        description: 'Runner\'s maintenance notes.'
      field :managers, ::Types::Ci::RunnerManagerType.connection_type, null: true,
        description: 'Runner managers associated with the runner configuration.',
        resolver: Resolvers::Ci::RunnerManagersResolver
      field :maximum_timeout, GraphQL::Types::Int, null: true,
        description: 'Maximum timeout (in seconds) for jobs processed by the runner.'
      field :owner_project, ::Types::ProjectType, null: true,
        description: 'Project that owns the runner. For project runners only.',
        resolver: ::Resolvers::Ci::RunnerOwnerProjectResolver
      field :paused, GraphQL::Types::Boolean, null: false,
        description: 'Indicates the runner is paused and not available to run jobs.'
      field :project_count, GraphQL::Types::Int, null: true,
        description: 'Number of projects that the runner is associated with.'
      field :projects,
        ::Types::ProjectType.connection_type,
        null: true,
        resolver: ::Resolvers::Ci::RunnerProjectsResolver,
        description: 'Find projects the runner is associated with. For project runners only.'
      field :register_admin_url, GraphQL::Types::String, null: true,
        description: 'URL of the temporary registration page of the runner. Only available before the runner is registered. Only available for administrators.'
      field :run_untagged, GraphQL::Types::Boolean, null: false,
        description: 'Indicates the runner is able to run untagged jobs.'
      field :runner_type, ::Types::Ci::RunnerTypeEnum, null: false,
        description: 'Type of the runner.'
      field :short_sha, GraphQL::Types::String, null: true,
        description: %q(First eight characters of the runner's token used to authenticate new job requests. Used as the runner's unique ID.)
      field :status,
        Types::Ci::RunnerStatusEnum,
        null: false,
        description: 'Status of the runner.'
      field :tag_list, [GraphQL::Types::String], null: true,
        description: 'Tags associated with the runner.'
      field :token_expires_at, Types::TimeType, null: true,
        description: 'Runner token expiration time.'

      markdown_field :maintenance_note_html, null: true

      def maintenance_note_html_resolver
        ::MarkupHelper.markdown(object.maintenance_note, context.to_h.dup)
      end

      def admin_url
        Gitlab::Routing.url_helpers.admin_runner_url(runner) if can_read_all_runners?
      end

      def edit_admin_url
        Gitlab::Routing.url_helpers.edit_admin_runner_url(runner) if can_admin_all_runners?
      end

      def ephemeral_register_url
        return unless context[:current_user]&.can?(:read_ephemeral_token, runner) && runner.registration_available?

        case runner.runner_type
        when 'instance_type'
          Gitlab::Routing.url_helpers.register_admin_runner_url(runner)
        when 'group_type'
          Gitlab::Routing.url_helpers.register_group_runner_url(runner.groups[0], runner)
        when 'project_type'
          Gitlab::Routing.url_helpers.register_project_runner_url(runner.projects[0], runner)
        end
      end

      def register_admin_url
        return unless can_admin_all_runners? && runner.registration_available?

        Gitlab::Routing.url_helpers.register_admin_runner_url(runner)
      end

      def ephemeral_authentication_token
        runner.token if runner.registration_available?
      end

      def project_count
        BatchLoader::GraphQL.for(runner.id).batch(key: :runner_project_count) do |ids, loader, args|
          counts = ::Ci::Runner.project_type
            .select(:id, 'COUNT(ci_runner_projects.id) as count')
            .left_outer_joins(:runner_projects)
            .id_in(ids)
            .group(:id) # rubocop: disable CodeReuse/ActiveRecord
            .index_by(&:id)

          ids.each { |id| loader.call(id, counts[id]&.count) }
        end
      end

      def job_execution_status
        BatchLoader::GraphQL.for(runner.id).batch(key: :running_builds_exist) do |runner_ids, loader|
          statuses = ::Ci::Runner.id_in(runner_ids).with_executing_builds.index_by(&:id)

          runner_ids.each do |runner_id|
            loader.call(runner_id, statuses[runner_id] ? :active : :idle)
          end
        end
      end

      private

      def can_admin_all_runners?
        context[:current_user]&.can_admin_all_resources?
      end

      def can_read_all_runners?
        context[:current_user]&.can?(:read_admin_cicd)
      end
    end
  end
end

Types::Ci::RunnerType.prepend_mod_with('Types::Ci::RunnerType')
