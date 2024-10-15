# frozen_string_literal: true

module Users
  class BanService < BannedUserBaseService
    extend ::Gitlab::Utils::Override

    private

    def update_user(user)
      if user.ban
        ban_duplicate_users(user)
        true
      else
        false
      end
    end

    def valid_state?(user)
      user.active?
    end

    def action
      :ban
    end

    def ban_duplicate_users(user)
      AntiAbuse::BanDuplicateUsersWorker.perform_async(user.id)
    end
  end
end

Users::BanService.prepend_mod_with('Users::BanService')
