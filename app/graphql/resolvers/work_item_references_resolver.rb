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

      apply_lookahead(find_work_items(refs))
    end

    private

    attr_reader :container

    def find_work_items(references)
      epic_refs, issue_refs = references.partition { |r| r.match?(/epics|&/) }
      item_ids = references_extractor(issue_refs)&.references(:work_item, ids_only: true) || []

      # Also check for references with :issue and :epic patterns to find legacy items
      item_ids << references_extractor(issue_refs)&.references(:issue, ids_only: true)
      item_ids << references_extractor(epic_refs)&.references(:epic)&.pluck(:issue_id)

      WorkItem.id_in(item_ids.flatten.compact)
    end

    def references_extractor(refs)
      return unless refs.any?

      extractor, analyze_context =
        if container.is_a?(Group)
          [::Gitlab::ReferenceExtractor.new(nil, context[:current_user]), { group: container }]
        else
          [::Gitlab::ReferenceExtractor.new(container, context[:current_user]), {}]
        end

      extractor.analyze(refs.join(' '), analyze_context)

      extractor
    end

    def find_object(full_path)
      Routable.find_by_full_path(full_path)
    end

    def unconditional_includes
      [{ namespace: [:organization] }, *super]
    end
  end
end
