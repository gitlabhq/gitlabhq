# frozen_string_literal: true

module Users
  class BanService < BannedUserBaseService
    extend ::Gitlab::Utils::Override

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

    override :track_event
    def track_event(user)
      experiment(:phone_verification_for_low_risk_users, user: user).track(:banned)
    end
  end
end

Users::BanService.prepend_mod_with('Users::BanService')
