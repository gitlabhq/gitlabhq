# frozen_string_literal: true

module Types
  module Ci
    class RunnerManagerType < BaseObject
      graphql_name 'CiRunnerManager'

      connection_type_class ::Types::CountableConnectionType

      authorize :read_runner_manager

      alias_method :runner_manager, :object

      field :architecture_name, GraphQL::Types::String, null: true,
        description: 'Architecture provided by the runner manager.',
        method: :architecture
      field :contacted_at, Types::TimeType, null: true,
        description: 'Timestamp of last contact from the runner manager.'
      field :created_at, Types::TimeType, null: true,
        description: 'Timestamp of creation of the runner manager.'
      field :executor_name, GraphQL::Types::String, null: true,
        description: 'Executor last advertised by the runner.'
      field :id, ::Types::GlobalIDType[::Ci::RunnerManager], null: false,
        description: 'ID of the runner manager.'
      field :ip_address, GraphQL::Types::String, null: true,
        description: 'IP address of the runner manager.'
      field :job_execution_status,
        Types::Ci::RunnerJobExecutionStatusEnum,
        null: true,
        description: 'Job execution status of the runner manager.',
        experiment: { milestone: '16.3' }
      field :platform_name, GraphQL::Types::String, null: true,
        description: 'Platform provided by the runner manager.',
        method: :platform
      field :revision, GraphQL::Types::String, null: true, description: 'Revision of the runner.'
      field :runner, RunnerType, null: true, description: 'Runner configuration for the runner manager.'
      field :status,
        Types::Ci::RunnerStatusEnum,
        null: false,
        description: 'Status of the runner manager.'
      field :system_id, GraphQL::Types::String,
        null: false,
        description: 'System ID associated with the runner manager.',
        method: :system_xid
      field :version, GraphQL::Types::String, null: true, description: 'Version of the runner.'

      def executor_name
        ::Ci::RunnerManager::EXECUTOR_TYPE_TO_NAMES[runner_manager.executor_type&.to_sym]
      end

      def job_execution_status
        BatchLoader::GraphQL.for(runner_manager.id).batch(key: :running_builds_exist) do |runner_manager_ids, loader|
          statuses = ::Ci::RunnerManager.id_in(runner_manager_ids).with_executing_builds.index_by(&:id)

          runner_manager_ids.each do |runner_manager_id|
            loader.call(runner_manager_id, statuses[runner_manager_id] ? :active : :idle)
          end
        end
      end
    end
  end
end

Types::Ci::RunnerManagerType.prepend_mod_with('Types::Ci::RunnerManagerType')
