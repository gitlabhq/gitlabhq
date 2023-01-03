# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    class RunnerCountableConnectionType < ::Types::CountableConnectionType
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end

Types::Ci::RunnerCountableConnectionType.prepend_mod
