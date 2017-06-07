module EE
  module WikiPages
    # BaseService EE mixin
    #
    # This module is intended to encapsulate EE-specific service logic
    # and be included in the `WikiPages::BaseService` service
    module BaseService
      extend ActiveSupport::Concern

      private

      def execute_hooks(page, action = 'create')
        super
        process_wiki_repository_update
      end

      def process_wiki_repository_update
        if ::Gitlab::Geo.primary?
          # Create wiki repository updated event on Geo event log
          ::Geo::RepositoryUpdatedEventStore.new(project, source: Geo::RepositoryUpdatedEvent::WIKI).create

          # Triggers repository update on secondary nodes
          ::Gitlab::Geo.notify_wiki_update(project)
        end
      end
    end
  end
end
