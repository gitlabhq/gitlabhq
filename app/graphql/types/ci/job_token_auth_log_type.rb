# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes -- this type is authorized by the resolver
  module Ci
    class JobTokenAuthLogType < BaseObject
      graphql_name 'CiJobTokenAuthLog'
      connection_type_class Types::CountableConnectionType

      field :origin_project, Types::Ci::JobTokenAccessibleProjectType,
        null: false,
        experiment: { milestone: '17.6' },
        description: 'Origin project.'

      field :last_authorized_at, Types::TimeType,
        null: false,
        experiment: { milestone: '17.6' },
        description: 'Last authorization date time.'
    end
  end
  # rubocop: enable Graphql/AuthorizeTypes
end
