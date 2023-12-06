# frozen_string_literal: true

module Resolvers
  class WorkItemReferencesResolver < BaseResolver
    prepend ::WorkItems::LookAheadPreloads
    include Gitlab::Graphql::Authorize::AuthorizeResource

    REFERENCES_LIMIT = 10

    authorize :read_work_item

    type ::Types::WorkItemType.connection_type, null: true

    argument :context_namespace_path, GraphQL::Types::ID,
      required: false,
      description: 'Full path of the context namespace (project or group).'

    argument :refs, [GraphQL::Types::String], required: true,
      description: 'Work item references. Can be either a short reference or URL.'

    def ready?(**args)
      if args[:refs].size > REFERENCES_LIMIT
        raise Gitlab::Graphql::Errors::ArgumentError,
          format(
            _('Number of references exceeds the limit. ' \
              'Please provide no more than %{refs_limit} references at the same time.'),
            refs_limit: REFERENCES_LIMIT
          )
      end

      super
    end

    def resolve_with_lookahead(context_namespace_path: nil, refs: [])
      return WorkItem.none if refs.empty?

      @container = authorized_find!(context_namespace_path)
      # Only ::Project is supported at the moment, future iterations will include ::Group.
      # See https://gitlab.com/gitlab-org/gitlab/-/issues/432555
      return WorkItem.none if container.is_a?(::Group)

      apply_lookahead(find_work_items(refs))
    end

    private

    attr_reader :container

    # rubocop: disable CodeReuse/ActiveRecord -- #references is not an ActiveRecord method
    def find_work_items(references)
      links, short_references = references.partition { |r| r.include?('/work_items/') }

      item_ids = references_extractor(short_references).references(:issue, ids_only: true)
      item_ids << references_extractor(links).references(:work_item, ids_only: true) if links.any?

      WorkItem.id_in(item_ids.flatten)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def references_extractor(refs)
      extractor = ::Gitlab::ReferenceExtractor.new(container, context[:current_user])
      extractor.analyze(refs.join(' '), {})

      extractor
    end

    def find_object(full_path)
      Routable.find_by_full_path(full_path)
    end
  end
end
