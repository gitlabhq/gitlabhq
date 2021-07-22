# frozen_string_literal: true

module Resolvers
  class LabelsResolver < BaseResolver
    include Gitlab::Graphql::Authorize::AuthorizeResource

    authorize :read_label

    type Types::LabelType.connection_type, null: true

    argument :search_term, GraphQL::Types::String,
             required: false,
             description: 'A search term to find labels with.'

    argument :include_ancestor_groups, GraphQL::Types::Boolean,
             required: false,
             description: 'Include labels from ancestor groups.',
             default_value: false

    def resolve(**args)
      return Label.none if parent.nil?

      authorize!(parent)

      # LabelsFinder uses `search` param, so we transform `search_term` into `search`
      args[:search] = args.delete(:search_term)
      LabelsFinder.new(current_user, parent_param.merge(args)).execute
    end

    private

    def parent
      object.respond_to?(:sync) ? object.sync : object
    end

    def parent_param
      key = case parent
            when Group then :group
            when Project then :project
            else raise "Unexpected parent type: #{parent.class}"
            end

      { "#{key}": parent }
    end
  end
end
