# frozen_string_literal: true

module WorkItems
  module SavedViews
    class SavedViewPolicy < BasePolicy
      delegate { saved_view_container }

      # Require users be logged in before they can create, read, update or delete saved views
      rule { anonymous }.prevent_all

      # Require users to be able to read the namespace before they can interact with saved views
      rule { ~can_read_namespace }.prevent_all

      # Only authors are granted access to shared views that are private
      rule { is_private & ~is_author }.prevent_all

      # Only the author can change a shared saved view's visibility, regardless of role
      rule { ~is_author }.prevent :update_saved_view_visibility

      condition(:can_read_namespace) do
        can?(:read_namespace, @subject.namespace)
      end

      condition(:is_author) do
        @user && @subject.created_by_id == @user.id
      end

      condition(:is_private) do
        @subject.private?
      end

      rule { ~can?(:_update_shared_saved_view) & ~is_author }.prevent :update_saved_view
      rule { ~can?(:_delete_shared_saved_view) & ~is_author }.prevent :delete_saved_view

      rule { ~is_private }.policy do
        enable :read_saved_view
      end

      private

      def saved_view_container
        namespace = @subject.namespace
        namespace.is_a?(Group) ? namespace : namespace.project
      end
    end
  end
end
