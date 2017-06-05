module EE
  # PostReceive EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be prepended in the `PostReceive` worker
  module PostReceive
    extend ActiveSupport::Concern
    extend ::Gitlab::CurrentSettings

    private

    def after_project_changes_hooks(post_received, user, refs, changes)
      super

      # Generate repository updated event on Geo event log when Geo is enabled
      ::Geo::RepositoryUpdatedEventStore.new(post_received.project, refs: refs, changes: changes).create
    end

    def process_wiki_changes(post_received)
      super

      update_wiki_es_indexes(post_received)

      if ::Gitlab::Geo.enabled?
        # Create wiki repository updated event on Geo event log
        ::Geo::RepositoryUpdatedEventStore.new(post_received.project, source: Geo::RepositoryUpdatedEvent::WIKI).create

        # Triggers repository update on secondary nodes
        ::Gitlab::Geo.notify_wiki_update(post_received.project)
      end
    end

    def update_wiki_es_indexes(post_received)
      return unless current_application_settings.elasticsearch_indexing?

      post_received.project.wiki.index_blobs
    end
  end
end
