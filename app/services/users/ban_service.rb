# frozen_string_literal: true

module Users
  class BanService < BannedUserBaseService
    private

    def update_user(user)
      user.ban
    end

    def valid_state?(user)
      user.active?
    end

    def action
      :ban
    end
  end
end
