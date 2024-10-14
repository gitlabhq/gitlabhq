# frozen_string_literal: true

module Resolvers
  class AbuseReportLabelsResolver < BaseResolver
    include Gitlab::Graphql::Authorize::AuthorizeResource

    authorize :read_label

    type Types::AntiAbuse::AbuseReportLabelType.connection_type, null: true

    argument :search_term, GraphQL::Types::String,
      required: false,
      description: 'Search term to find labels with.'

    def resolve(**args)
      ::Admin::AbuseReportLabelsFinder.new(context[:current_user], args).execute
    end
  end
end
