# frozen_string_literal: true

module Boards
  module Lists
    class UpdateService < Boards::Lists::BaseUpdateService
      def can_read?(list)
        Ability.allowed?(current_user, :read_issue_board_list, parent)
      end

      def can_admin?(list)
        Ability.allowed?(current_user, :admin_issue_board_list, parent)
      end
    end
  end
end

Boards::Lists::UpdateService.prepend_mod_with('Boards::Lists::UpdateService')
