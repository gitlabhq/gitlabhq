# frozen_string_literal: true

module Resolvers
  class WorkItemsResolver < BaseResolver
    prepend ::WorkItems::LookAheadPreloads
    include SearchArguments
    include ::WorkItems::SharedFilterArguments

    argument :iid,
      GraphQL::Types::String,
      required: false,
      description: 'IID of the work item. For example, "1".'
    argument :sort,
      Types::WorkItems::SortEnum,
      description: 'Sort work items by criteria.',
      required: false,
      default_value: :created_desc

    type Types::WorkItemType.connection_type, null: true

    def resolve_with_lookahead(**args)
      return WorkItem.none if resource_parent.nil?

      finder = choose_finder(args)

      Gitlab::Graphql::Loaders::IssuableLoader
        .new(resource_parent, finder)
        .batching_find_all { |q| apply_lookahead(q) }
    end

    private

    def choose_finder(args)
      if ::Feature.enabled?(:glql_es_integration, current_user)
        glql_finder = glql_finder(args)

        return glql_finder if glql_finder.use_elasticsearch_finder?
      end

      finder(prepare_finder_params(args))
    end

    def glql_finder(args)
      ::WorkItems::Glql::WorkItemsFinder.new(current_user, context, resource_parent, args)
    end

    # When we search on a group level, this finder is being overwritten in
    # app/graphql/resolvers/namespaces/work_items_resolver.rb:32
    def finder(args)
      ::WorkItems::WorkItemsFinder.new(current_user, args)
    end

    def prepare_finder_params(args)
      params = super(args)
      params[:iids] ||= [params.delete(:iid)].compact if params[:iid]

      params
    end

    def resource_parent
      # The project could have been loaded in batch by `BatchLoader`.
      # At this point we need the `id` of the project to query for work items, so
      # make sure it's loaded and not `nil` before continuing.
      strong_memoize(:resource_parent) do
        object.respond_to?(:sync) ? object.sync : object
      end
    end
  end
end

Resolvers::WorkItemsResolver.prepend_mod
