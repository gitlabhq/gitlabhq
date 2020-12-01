# frozen_string_literal: true

module Types
  module Ci
    class PipelineType < BaseObject
      graphql_name 'Pipeline'

      connection_type_class(Types::CountableConnectionType)

      authorize :read_pipeline

      expose_permissions Types::PermissionTypes::Ci::Pipeline

      field :id, GraphQL::ID_TYPE, null: false,
            description: 'ID of the pipeline'

      field :iid, GraphQL::STRING_TYPE, null: false,
            description: 'Internal ID of the pipeline'

      field :sha, GraphQL::STRING_TYPE, null: false,
            description: "SHA of the pipeline's commit"

      field :before_sha, GraphQL::STRING_TYPE, null: true,
            description: 'Base SHA of the source branch'

      field :status, PipelineStatusEnum, null: false,
            description: "Status of the pipeline (#{::Ci::Pipeline.all_state_names.compact.join(', ').upcase})"

      field :detailed_status, Types::Ci::DetailedStatusType, null: false,
            description: 'Detailed status of the pipeline'

      field :config_source, PipelineConfigSourceEnum, null: true,
            description: "Config source of the pipeline (#{::Enums::Ci::Pipeline.config_sources.keys.join(', ').upcase})"

      field :duration, GraphQL::INT_TYPE, null: true,
            description: 'Duration of the pipeline in seconds'

      field :coverage, GraphQL::FLOAT_TYPE, null: true,
            description: 'Coverage percentage'

      field :created_at, Types::TimeType, null: false,
            description: "Timestamp of the pipeline's creation"

      field :updated_at, Types::TimeType, null: false,
            description: "Timestamp of the pipeline's last activity"

      field :started_at, Types::TimeType, null: true,
            description: 'Timestamp when the pipeline was started'

      field :finished_at, Types::TimeType, null: true,
            description: "Timestamp of the pipeline's completion"

      field :committed_at, Types::TimeType, null: true,
            description: "Timestamp of the pipeline's commit"

      field :stages, Types::Ci::StageType.connection_type, null: true,
            description: 'Stages of the pipeline',
            extras: [:lookahead],
            resolver: Resolvers::Ci::PipelineStagesResolver

      field :user, Types::UserType, null: true,
            description: 'Pipeline user'

      field :retryable, GraphQL::BOOLEAN_TYPE,
            description: 'Specifies if a pipeline can be retried',
            method: :retryable?,
            null: false

      field :cancelable, GraphQL::BOOLEAN_TYPE,
            description: 'Specifies if a pipeline can be canceled',
            method: :cancelable?,
            null: false

      field :jobs,
            ::Types::Ci::JobType.connection_type,
            null: true,
            description: 'Jobs belonging to the pipeline',
            resolver: ::Resolvers::Ci::JobsResolver

      field :source_job, Types::Ci::JobType, null: true,
            description: 'Job where pipeline was triggered from'

      field :downstream, Types::Ci::PipelineType.connection_type, null: true,
            description: 'Pipelines this pipeline will trigger',
            method: :triggered_pipelines_with_preloads

      field :upstream, Types::Ci::PipelineType, null: true,
            description: 'Pipeline that triggered the pipeline',
            method: :triggered_by_pipeline

      field :path, GraphQL::STRING_TYPE, null: true,
            description: "Relative path to the pipeline's page"

      field :project, Types::ProjectType, null: true,
            description: 'Project the pipeline belongs to'

      def detailed_status
        object.detailed_status(context[:current_user])
      end

      def user
        Gitlab::Graphql::Loaders::BatchModelLoader.new(User, object.user_id).find
      end

      def path
        ::Gitlab::Routing.url_helpers.project_pipeline_path(object.project, object)
      end
    end
  end
end

Types::Ci::PipelineType.prepend_if_ee('::EE::Types::Ci::PipelineType')
