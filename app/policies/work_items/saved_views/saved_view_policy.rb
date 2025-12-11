# frozen_string_literal: true

module WorkItems
  module SavedViews
    class SavedViewPolicy < BasePolicy
      # Require users be logged in before they can create, read, update or delete saved views
      rule { anonymous }.prevent_all

      condition(:can_read_namespace) do
        can?(:read_namespace, @subject.namespace)
      end

      condition(:is_author) do
        @user && @subject.created_by_id == @user.id
      end

      condition(:has_planner_access) do
        namespace = @subject.namespace
        container = namespace.is_a?(Group) ? namespace : namespace.project

        container.member?(@user) && container.max_member_access_for_user(@user) >= Gitlab::Access::PLANNER
      end

      condition(:is_private) do
        @subject.private?
      end

      rule { has_planner_access & ~is_private }.policy do
        enable :update_saved_view
        enable :delete_saved_view
      end

      rule { can_read_namespace & is_author }.policy do
        enable :read_saved_view
        enable :update_saved_view
        enable :delete_saved_view
      end

      rule { can_read_namespace & ~is_private }.policy do
        enable :read_saved_view
      end
    end
  end
end
