# frozen_string_literal: true

module Users
  class UnbanService < BannedUserBaseService
    private

    def update_user(user)
      user.unban
    end

    def valid_state?(user)
      user.banned?
    end

    def action
      :unban
    end
  end
end

Users::UnbanService.prepend_mod_with('Users::UnbanService')
