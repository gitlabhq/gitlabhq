# frozen_string_literal: true

module Types
  module Ci
    class RunnerMachineType < BaseObject
      graphql_name 'CiRunnerMachine'

      connection_type_class(::Types::CountableConnectionType)

      authorize :read_runner_machine

      alias_method :runner_machine, :object

      field :architecture_name, GraphQL::Types::String, null: true,
        description: 'Architecture provided by the runner machine.',
        method: :architecture
      field :contacted_at, Types::TimeType, null: true,
        description: 'Timestamp of last contact from the runner machine.',
        method: :contacted_at
      field :created_at, Types::TimeType, null: true,
        description: 'Timestamp of creation of the runner machine.'
      field :executor_name, GraphQL::Types::String, null: true,
        description: 'Executor last advertised by the runner.',
        method: :executor_name
      field :id, ::Types::GlobalIDType[::Ci::RunnerMachine], null: false,
        description: 'ID of the runner machine.'
      field :ip_address, GraphQL::Types::String, null: true,
        description: 'IP address of the runner machine.'
      field :platform_name, GraphQL::Types::String, null: true,
        description: 'Platform provided by the runner machine.',
        method: :platform
      field :revision, GraphQL::Types::String, null: true, description: 'Revision of the runner.'
      field :runner, RunnerType, null: true, description: 'Runner configuration for the runner machine.'
      field :status,
        Types::Ci::RunnerStatusEnum,
        null: false,
        description: 'Status of the runner machine.'
      field :version, GraphQL::Types::String, null: true, description: 'Version of the runner.'

      def executor_name
        ::Ci::Runner::EXECUTOR_TYPE_TO_NAMES[runner_machine.executor_type&.to_sym]
      end
    end
  end
end

Types::Ci::RunnerType.prepend_mod_with('Types::Ci::RunnerType')
