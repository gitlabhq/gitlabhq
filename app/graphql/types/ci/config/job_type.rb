# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    module Config
      class JobType < BaseObject
        graphql_name 'CiConfigJob'

        field :name, GraphQL::Types::String, null: true,
              description: 'Name of the job.'
        field :group_name, GraphQL::Types::String, null: true,
              description: 'Name of the job group.'
        field :stage, GraphQL::Types::String, null: true,
              description: 'Name of the job stage.'
        field :needs, Types::Ci::Config::NeedType.connection_type, null: true,
              description: 'Builds that must complete before the jobs run.'
        field :allow_failure, GraphQL::Types::Boolean, null: true,
              description:  'Allow job to fail.'
        field :before_script, [GraphQL::Types::String], null: true,
              description: 'Override a set of commands that are executed before the job.'
        field :script, [GraphQL::Types::String], null: true,
              description: 'Shell script that is executed by a runner.'
        field :after_script, [GraphQL::Types::String], null: true,
              description: 'Override a set of commands that are executed after the job.'
        field :when, GraphQL::Types::String, null: true,
              description: 'When to run the job.',
              resolver_method: :restrict_when_to_run_jobs
        field :environment, GraphQL::Types::String, null: true,
              description: 'Name of an environment to which the job deploys.'
        field :except, Types::Ci::Config::JobRestrictionType, null: true,
              description: 'Limit when jobs are not created.'
        field :only, Types::Ci::Config::JobRestrictionType, null: true,
               description: 'Jobs are created when these conditions do not apply.'
        field :tags, [GraphQL::Types::String], null: true,
              description: 'List of tags that are used to select a runner.'

        def restrict_when_to_run_jobs
          object[:when]
        end
      end
    end
  end
end
