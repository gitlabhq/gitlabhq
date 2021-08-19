# frozen_string_literal: true

module Users
  class UnbanService < BannedUserBaseService
    private

    def update_user(user)
      user.activate
    end

    def action
      :unban
    end
  end
end
