# frozen_string_literal: true

module Resolvers
  class LabelsResolver < BaseResolver
    include Gitlab::Graphql::Authorize::AuthorizeResource

    authorize :read_label

    type Types::LabelType.connection_type, null: true

    argument :title, GraphQL::Types::String,
      required: false,
      description: 'Exact match on title. Cannot be used with `searchTerm`. ' \
        '`searchIn` will be ignored if `title` argument is provided.'

    argument :search_term, GraphQL::Types::String,
      required: false,
      description: 'Search term to find labels with.'

    argument :search_in, [Types::Issuables::Labels::SearchFieldListEnum],
      default_value: [:title, :description],
      description: 'Specify which fields to search in. Ignored if using `title`.'

    argument :include_ancestor_groups, GraphQL::Types::Boolean,
      required: false,
      description: 'Include labels from ancestor groups.',
      default_value: false

    before_connection_authorization do |nodes, current_user|
      Preloaders::LabelsPreloader.new(nodes, current_user).preload_all
    end

    validates mutually_exclusive: [:search_term, :title]

    def resolve(**args)
      return Label.none if parent.nil?

      authorize!(parent)

      # LabelsFinder uses `search` param, so we transform `search_term` into `search`
      args[:search] = args.delete(:search_term)

      # If `title` is used, remove `search_in`
      args.delete(:search_in) if args[:title]

      # Optimization:
      # Rely on the LabelsPreloader rather than the default parent record preloading in the
      # finder because LabelsPreloader preloads more associations which are required for the
      # permission check.
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
