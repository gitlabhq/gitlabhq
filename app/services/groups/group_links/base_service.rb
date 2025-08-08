# frozen_string_literal: true

module Groups # rubocop:disable Gitlab/BoundedContexts -- the Groups module already exists and holds other services as well
  module GroupLinks
    class BaseService < ::Groups::BaseService
      private

      def priority_for_refresh
        UserProjectAccessChangedService::MEDIUM_PRIORITY
      end
    end
  end
end
