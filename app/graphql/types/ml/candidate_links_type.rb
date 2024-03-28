# frozen_string_literal: true

module Types
  module Ml
    # rubocop: disable Graphql/AuthorizeTypes -- authorization in ModelDetailsResolver
    class CandidateLinksType < BaseObject
      graphql_name 'MLCandidateLinks'
      description 'Represents links to perform actions on the candidate'

      present_using ::Ml::CandidatePresenter

      field :show_path, GraphQL::Types::String,
        null: true, description: 'Path to the details page of the candidate.', method: :path

      field :artifact_path, GraphQL::Types::String,
        null: true,
        description: 'Path to the artifact.',
        method: :artifact_show_path
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
