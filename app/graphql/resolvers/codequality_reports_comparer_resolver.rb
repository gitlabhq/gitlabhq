# frozen_string_literal: true

module Resolvers
  class CodequalityReportsComparerResolver < BaseResolver
    include Gitlab::Graphql::Authorize::AuthorizeResource

    type ::Types::Security::CodequalityReportsComparerType, null: true

    authorize :read_build

    def resolve
      authorize!(object.actual_head_pipeline)

      object.compare_codequality_reports
    end
  end
end
