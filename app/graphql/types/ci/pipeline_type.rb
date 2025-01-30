# frozen_string_literal: true

module Types
  module Ci
    class PipelineType < BaseObject
      graphql_name 'Pipeline'

      connection_type_class Types::CountableConnectionType

      authorize :read_pipeline
      present_using ::Ci::PipelinePresenter

      expose_permissions Types::PermissionTypes::Ci::Pipeline

      field :id, GraphQL::Types::ID, null: false,
        description: 'ID of the pipeline.'

      field :iid, GraphQL::Types::String, null: false,
        description: 'Internal ID of the pipeline.'

      field :name, GraphQL::Types::String, null: true,
        description: 'Name of the pipeline.'

      field :sha, GraphQL::Types::String, null: true,
        description: "SHA of the pipeline's commit." do
        argument :format,
          type: Types::ShaFormatEnum,
          required: false,
          description: 'Format of the SHA.'
      end

      field :before_sha, GraphQL::Types::String, null: true,
        description: 'Base SHA of the source branch.',
        calls_gitaly: true

      field :complete, GraphQL::Types::Boolean, null: false, method: :complete?,
        description: 'Indicates if a pipeline is complete.'

      field :status, PipelineStatusEnum, null: false,
        description: "Status of the pipeline (#{::Ci::Pipeline.all_state_names.compact.join(', ').upcase})"

      field :warnings, GraphQL::Types::Boolean, null: false, method: :has_warnings?,
        description: "Indicates if a pipeline has warnings."

      field :detailed_status, Types::Ci::DetailedStatusType, null: false,
        description: 'Detailed status of the pipeline.'

      field :config_source, PipelineConfigSourceEnum, null: true,
        description: "Configuration source of the pipeline (#{::Enums::Ci::Pipeline.config_sources.keys.join(', ').upcase})"

      field :duration, GraphQL::Types::Int, null: true,
        description: 'Duration of the pipeline in seconds.'

      field :queued_duration, Types::DurationType, null: true,
        description: 'How long the pipeline was queued before starting.'

      field :coverage, GraphQL::Types::Float, null: true,
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
        authorize: :read_build,
        description: 'Stages of the pipeline.',
        extras: [:lookahead],
        resolver: Resolvers::Ci::PipelineStagesResolver

      field :user,
        type: 'Types::UserType',
        null: true,
        description: 'Pipeline user.'

      field :retryable, GraphQL::Types::Boolean,
        description: 'Specifies if a pipeline\'s jobs can be retried.',
        method: :retryable?,
        null: false

      field :cancelable, GraphQL::Types::Boolean,
        description: 'Specifies if a pipeline can be canceled.',
        method: :cancelable?,
        null: false

      field :jobs,
        ::Types::Ci::JobType.connection_type,
        null: true,
        authorize: :read_build,
        description: 'Jobs belonging to the pipeline.',
        resolver: ::Resolvers::Ci::JobsResolver

      field :job,
        type: ::Types::Ci::JobType,
        null: true,
        authorize: :read_build,
        description: 'Specific job in the pipeline, either by name or ID.' do
        argument :id,
          type: ::Types::GlobalIDType[::CommitStatus],
          required: false,
          description: 'ID of the job.'
        argument :name,
          type: ::GraphQL::Types::String,
          required: false,
          description: 'Name of the job.'
      end

      field :job_artifacts,
        null: true,
        description: 'Job artifacts of the pipeline.',
        resolver: ::Resolvers::Ci::PipelineJobArtifactsResolver

      field :source_job,
        type: Types::Ci::JobType,
        null: true,
        authorize: :read_build,
        description: 'Job where pipeline was triggered from.'

      field :downstream, Types::Ci::PipelineType.connection_type, null: true,
        description: 'Pipelines the pipeline will trigger.',
        method: :triggered_pipelines_with_preloads

      field :upstream, Types::Ci::PipelineType, null: true,
        description: 'Pipeline that triggered the pipeline.',
        method: :triggered_by_pipeline

      field :path, GraphQL::Types::String, null: true,
        description: "Relative path to the pipeline's page."

      field :commit, Types::Repositories::CommitType, null: true,
        description: "Git commit of the pipeline.",
        calls_gitaly: true

      field :commit_path, GraphQL::Types::String, null: true,
        description: 'Path to the commit that triggered the pipeline.'

      field :project, Types::ProjectType, null: true,
        description: 'Project the pipeline belongs to.'

      field :active, GraphQL::Types::Boolean, null: false, method: :active?,
        description: 'Indicates if the pipeline is active.'

      field :uses_needs, GraphQL::Types::Boolean, null: true,
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

      field :ref, GraphQL::Types::String, null: true,
        description: 'Reference to the branch from which the pipeline was triggered.'

      field :ref_path, GraphQL::Types::String, null: true,
        description: 'Reference path to the branch from which the pipeline was triggered.',
        method: :source_ref_path

      field :warning_messages, Types::Ci::PipelineMessageType.connection_type, null: true,
        description: 'Pipeline warning messages.'

      field :error_messages, Types::Ci::PipelineMessageType.connection_type, null: true,
        description: 'Pipeline error messages.'

      field :merge_request_event_type, Types::Ci::PipelineMergeRequestEventTypeEnum, null: true,
        description: "Event type of the pipeline associated with a merge request."

      field :total_jobs, GraphQL::Types::Int, null: false, method: :total_size, description: "Total number of jobs in the pipeline."

      field :failure_reason, GraphQL::Types::String, null: true, description: "Reason why the pipeline failed."

      field :triggered_by_path, GraphQL::Types::String, null: true, description: "Path that triggered the pipeline."

      field :source, GraphQL::Types::String, null: true, description: "Source of the pipeline."

      field :type, GraphQL::Types::String, null: false, description: "Type of the pipeline."

      field :child, GraphQL::Types::Boolean, null: false, method: :child?, description: "If the pipeline is a child or not."

      field :latest, GraphQL::Types::Boolean, null: false, method: :latest?, calls_gitaly: true, description: "If the pipeline is the latest one or not."

      field :ref_text, GraphQL::Types::String, null: false, description: "Reference text from the presenter.", calls_gitaly: true

      field :merge_request, Types::MergeRequestType, null: true, description: "MR which the Pipeline is attached to."

      field :stuck, GraphQL::Types::Boolean, method: :stuck?, null: false, description: "If the pipeline is stuck."

      field :yaml_errors, GraphQL::Types::Boolean, method: :yaml_errors?, null: false, description: "If the pipeline has YAML errors."

      field :yaml_error_messages, GraphQL::Types::String, method: :yaml_errors, null: true, description: "Pipeline YAML errors."

      field :trigger, GraphQL::Types::Boolean, method: :trigger?, null: false, description: "If the pipeline was created by a Trigger request."

      field :manual_variables, PipelineManualVariableType.connection_type, null: true, method: :variables, description: 'CI/CD variables added to a manual pipeline.'

      def commit
        BatchLoader::GraphQL.wrap(object.commit)
      end

      def error_messages
        BatchLoader::GraphQL.for(object).batch do |pipelines, loader|
          # rubocop: disable CodeReuse/ActiveRecord -- no need to bloat the Pipeline model, we only need this functionality for GraphQL
          messages = ::Ci::PipelineMessage.where(pipeline: pipelines, severity: :error)
          # rubocop: enable CodeReuse/ActiveRecord
          pipelines.each do |pipeline|
            loader.call(pipeline, messages.select { |m| m.pipeline_id == pipeline.id })
          end
        end
      end

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

      def warning_messages
        BatchLoader::GraphQL.for(object).batch do |pipelines, loader|
          # rubocop: disable CodeReuse/ActiveRecord -- context specific
          messages = ::Ci::PipelineMessage.where(pipeline: pipelines, severity: :warning)
          # rubocop: enable CodeReuse/ActiveRecord

          pipelines.each do |pipeline|
            loader.call(pipeline, messages.select { |m| m.pipeline_id == pipeline.id })
          end
        end
      end

      def job(id: nil, name: nil)
        raise ::Gitlab::Graphql::Errors::ArgumentError, 'One of id or name is required' unless id || name

        if id
          pipeline.statuses.id_in(id.model_id)
        else
          pipeline.latest_statuses.by_name(name)
        end.take # rubocop: disable CodeReuse/ActiveRecord
      end

      def sha(format: Types::ShaFormatEnum.enum[:long])
        return pipeline.short_sha if format == Types::ShaFormatEnum.enum[:short]

        pipeline.sha
      end

      alias_method :pipeline, :object
    end
  end
end

Types::Ci::PipelineType.prepend_mod_with('Types::Ci::PipelineType')
