# frozen_string_literal: true

module Resolvers
  module Notes
    # Resolves the quick actions available to the current user on a noteable
    # (for example a merge request), mirroring the set the web editor fetches
    # from `autocomplete_sources/commands`. Each command's availability is
    # evaluated server-side against the current user, the noteable's state, and
    # the namespace's licensed features.
    class AvailableQuickActionsResolver < BaseResolver
      # Some commands' availability conditions inspect the repository
      # (for example /merge, /target_branch), which calls Gitaly.
      calls_gitaly!

      type [::Types::Notes::QuickActionCommandType], null: true

      alias_method :noteable, :object

      def resolve
        return [] unless noteable && current_user
        return [] unless current_user.can?(:use_quick_actions)
        return [] unless current_user.can?(:create_note, noteable)

        container = noteable.resource_parent
        return [] unless container

        ::QuickActions::InterpretService
          .new(container: container, current_user: current_user)
          .available_commands(noteable)
      end
    end
  end
end
