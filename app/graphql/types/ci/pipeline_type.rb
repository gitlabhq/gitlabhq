# frozen_string_literal: true

module Types
  module Ci
    class PipelineType < BaseObject
      graphql_name 'Pipeline'

      connection_type_class(Types::CountableConnectionType)

      authorize :read_pipeline
      present_using ::Ci::PipelinePresenter

      expose_permissions Types::PermissionTypes::Ci::Pipeline

      field :id, GraphQL::ID_TYPE, null: false,
            description: 'ID of the pipeline.'

      field :iid, GraphQL::STRING_TYPE, null: false,
            description: 'Internal ID of the pipeline.'

      field :sha, GraphQL::STRING_TYPE, null: false,
            description: "SHA of the pipeline's commit."

      field :before_sha, GraphQL::STRING_TYPE, null: true,
            description: 'Base SHA of the source branch.'

      field :complete, GraphQL::BOOLEAN_TYPE, null: false, method: :complete?,
            description: 'Indicates if a pipeline is complete.'

      field :status, PipelineStatusEnum, null: false,
            description: "Status of the pipeline (#{::Ci::Pipeline.all_state_names.compact.join(', ').upcase})"

      field :warnings, GraphQL::BOOLEAN_TYPE, null: false, method: :has_warnings?,
            description: "Indicates if a pipeline has warnings."

      field :detailed_status, Types::Ci::DetailedStatusType, null: false,
            description: 'Detailed status of the pipeline.'

      field :config_source, PipelineConfigSourceEnum, null: true,
            description: "Configuration source of the pipeline (#{::Enums::Ci::Pipeline.config_sources.keys.join(', ').upcase})"

      field :duration, GraphQL::INT_TYPE, null: true,
            description: 'Duration of the pipeline in seconds.'

      field :queued_duration, Types::DurationType, null: true,
            description: 'How long the pipeline was queued before starting.'

      field :coverage, GraphQL::FLOAT_TYPE, null: true,
            description: 'Coverage percentage.'

      field :created_at, Types::TimeType, null: false,
            description: "Timestamp of the pipeline's creation."

      field :updated_at, Types::TimeType, null: false,
            description: "Timestamp of the pipeline's last activity."

      field :started_at, Types::TimeType, null: true,
            description: 'Timestamp when the pipeline was started.'

      field :finished_at, Types::TimeType, null: true,
            description: "Timestamp of the pipeline's completion."

      field :committed_at, Types::TimeType, null: true,
            description: "Timestamp of the pipeline's commit."

      field :stages,
            type: Types::Ci::StageType.connection_type,
            null: true,
            authorize: :read_commit_status,
            description: 'Stages of the pipeline.',
            extras: [:lookahead],
            resolver: Resolvers::Ci::PipelineStagesResolver

      field :user,
            type: Types::UserType,
            null: true,
            description: 'Pipeline user.'

      field :retryable, GraphQL::BOOLEAN_TYPE,
            description: 'Specifies if a pipeline can be retried.',
            method: :retryable?,
            null: false

      field :cancelable, GraphQL::BOOLEAN_TYPE,
            description: 'Specifies if a pipeline can be canceled.',
            method: :cancelable?,
            null: false

      field :jobs,
            ::Types::Ci::JobType.connection_type,
            null: true,
            authorize: :read_commit_status,
            description: 'Jobs belonging to the pipeline.',
            resolver: ::Resolvers::Ci::JobsResolver

      field :job,
            type: ::Types::Ci::JobType,
            null: true,
            authorize: :read_commit_status,
            description: 'A specific job in this pipeline, either by name or ID.' do
        argument :id,
                 type: ::Types::GlobalIDType[::CommitStatus],
                 required: false,
                 description: 'ID of the job.'
        argument :name,
                 type: ::GraphQL::STRING_TYPE,
                 required: false,
                 description: 'Name of the job.'
      end

      field :source_job,
            type: Types::Ci::JobType,
            null: true,
            authorize: :read_commit_status,
            description: 'Job where pipeline was triggered from.'

      field :downstream, Types::Ci::PipelineType.connection_type, null: true,
            description: 'Pipelines this pipeline will trigger.',
            method: :triggered_pipelines_with_preloads

      field :upstream, Types::Ci::PipelineType, null: true,
            description: 'Pipeline that triggered the pipeline.',
            method: :triggered_by_pipeline

      field :path, GraphQL::STRING_TYPE, null: true,
            description: "Relative path to the pipeline's page."

      field :commit_path, GraphQL::STRING_TYPE, null: true,
            description: 'Path to the commit that triggered the pipeline.'

      field :project, Types::ProjectType, null: true,
            description: 'Project the pipeline belongs to.'

      field :active, GraphQL::BOOLEAN_TYPE, null: false, method: :active?,
            description: 'Indicates if the pipeline is active.'

      field :uses_needs, GraphQL::BOOLEAN_TYPE, null: true,
            method: :uses_needs?,
            description: 'Indicates if the pipeline has jobs with `needs` dependencies.'

      field :test_report_summary,
            Types::Ci::TestReportSummaryType,
            null: false,
            description: 'Summary of the test report generated by the pipeline.',
            resolver: Resolvers::Ci::TestReportSummaryResolver

      field :test_suite,
            Types::Ci::TestSuiteType,
            null: true,
            description: 'A specific test suite in a pipeline test report.',
            resolver: Resolvers::Ci::TestSuiteResolver

      field :ref, GraphQL::STRING_TYPE, null: true,
            description: 'Reference to the branch from which the pipeline was triggered.'

      def detailed_status
        object.detailed_status(current_user)
      end

      def user
        Gitlab::Graphql::Loaders::BatchModelLoader.new(User, object.user_id).find
      end

      def commit_path
        ::Gitlab::Routing.url_helpers.project_commit_path(object.project, object.sha)
      end

      def path
        ::Gitlab::Routing.url_helpers.project_pipeline_path(object.project, object)
      end

      def job(id: nil, name: nil)
        raise ::Gitlab::Graphql::Errors::ArgumentError, 'One of id or name is required' unless id || name

        if id
          id = ::Types::GlobalIDType[::CommitStatus].coerce_isolated_input(id) if id
          pipeline.statuses.id_in(id.model_id)
        else
          pipeline.statuses.by_name(name)
        end.take # rubocop: disable CodeReuse/ActiveRecord
      end

      alias_method :pipeline, :object
    end
  end
end

Types::Ci::PipelineType.prepend_mod_with('Types::Ci::PipelineType')
