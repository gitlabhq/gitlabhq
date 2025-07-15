# frozen_string_literal: true

module Groups # rubocop:disable Gitlab/BoundedContexts -- the Groups module already exists and holds other services as well
  module GroupLinks
    class BaseService < ::Groups::BaseService
      private

      def priority_for_refresh(group)
        if Feature.enabled?(:change_priority_for_user_access_refresh_for_group_links, group.root_ancestor)
          return UserProjectAccessChangedService::MEDIUM_PRIORITY
        end

        UserProjectAccessChangedService::HIGH_PRIORITY
      end
    end
  end
end
