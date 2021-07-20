# frozen_string_literal: true

module Groups
  module GroupLinks
    class CreateService < Groups::BaseService
      def initialize(shared_group, shared_with_group, user, params)
        @shared_group = shared_group
        super(shared_with_group, user, params)
      end

      def execute
        unless shared_with_group && shared_group &&
               can?(current_user, :admin_group_member, shared_group) &&
               can?(current_user, :read_group, shared_with_group) &&
               sharing_allowed?
          return error('Not Found', 404)
        end

        link = GroupGroupLink.new(
          shared_group: shared_group,
          shared_with_group: shared_with_group,
          group_access: params[:shared_group_access],
          expires_at: params[:expires_at]
        )

        if link.save
          shared_with_group.refresh_members_authorized_projects(blocking: false, direct_members_only: true)
          success(link: link)
        else
          error(link.errors.full_messages.to_sentence, 409)
        end
      end

      private

      attr_reader :shared_group

      alias_method :shared_with_group, :group

      def sharing_allowed?
        sharing_outside_hierarchy_allowed? || within_hierarchy?
      end

      def sharing_outside_hierarchy_allowed?
        !shared_group.root_ancestor.namespace_settings.prevent_sharing_groups_outside_hierarchy
      end

      def within_hierarchy?
        shared_group.root_ancestor.self_and_descendants_ids.include?(shared_with_group.id)
      end
    end
  end
end
