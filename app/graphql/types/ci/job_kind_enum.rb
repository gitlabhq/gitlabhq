# frozen_string_literal: true

module Types
  module Ci
    class JobKindEnum < BaseEnum
      graphql_name 'CiJobKind'

      value 'BUILD', value: ::Ci::Build, description: 'Standard CI job.'
      value 'BRIDGE', value: ::Ci::Bridge, description: 'Bridge CI job connecting a parent and child pipeline.'
    end
  end
end
