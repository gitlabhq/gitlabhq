# frozen_string_literal: true

module WorkItems
  module QuickActions
    class DependencyService < ::WorkItems::QuickActions::BaseDependencyService
      def can_admin_link?
        return false unless @target.is_a?(Issue)

        @user.can?(:admin_issue_link, @target) # rubocop:disable Gitlab/Authz/PermissionCheck -- there is no more specific permission check for this.
      end

      def can_block?
        License.feature_available?(:blocked_issues) && can_admin_link?
      end

      def param_hint
        '<#item | group/project#item | item URL>'
      end

      def type_name
        @target.work_item_type.name.downcase
      end

      def parse_params(items)
        extractor = build_extractor(items)
        extractor.references(:issue) + extractor.references(:work_item) # rubocop:disable CodeReuse/ActiveRecord -- reference extraction requires AR queries
      end

      def create_link(items, link_type:)
        target = @target
        user = @user
        references = items.map { |item| item.to_reference(full: true) }

        link_service = proc do
          ::WorkItems::RelatedWorkItemLinks::CreateService.new(
            WorkItem.find(target.id),
            user, { issuable_references: references, link_type: link_type }
          ).execute
        end

        if target.persisted?
          link_service.call
        else
          target.run_after_commit(&link_service)
        end
      end

      def destroy_link(item)
        link = IssueLink.for_items(@target, item).first
        return unless link

        IssueLinks::DestroyService.new(link, @user).execute
      end
    end
  end
end

WorkItems::QuickActions::DependencyService.prepend_mod
