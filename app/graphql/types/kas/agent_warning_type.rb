# frozen_string_literal: true

require_relative 'agent_version_warning_type'

module Types
  module Kas
    # rubocop: disable Graphql/AuthorizeTypes -- authorization is performed outside
    class AgentWarningType < BaseObject
      graphql_name 'AgentWarning'
      description 'Warning object for a connected Agent'

      field :version,
        Types::Kas::AgentVersionWarningType,
        null: true,
        description: 'Agent warning related to the version.'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
