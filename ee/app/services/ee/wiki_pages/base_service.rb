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
          ::Geo::RepositoryUpdatedService.new(project, source: ::Geo::RepositoryUpdatedEvent::WIKI).execute
        end
      end
    end
  end
end
