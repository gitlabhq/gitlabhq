# frozen_string_literal: true

module Groups
  module GroupLinks
    class CreateService < BaseService
      def execute(shared_group)
        return false unless shared_group

        group.group_group_links.create(
          shared_group: shared_group,
          shared_with_group: group,
          group_access: params[:shared_group_access],
          expires_at: params[:expires_at]
        )
      end
    end
  end
end
