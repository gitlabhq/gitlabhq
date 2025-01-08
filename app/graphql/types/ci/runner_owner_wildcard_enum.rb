# frozen_string_literal: true

module Types
  module Ci
    class RunnerOwnerWildcardEnum < BaseEnum
      graphql_name 'CiRunnerOwnerWildcard'

      value 'ADMINISTRATORS',
        description: "Filter runners owned by an administrator.",
        value: :administrators
    end
  end
end
