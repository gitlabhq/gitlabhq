# frozen_string_literal: true

module CheckInitialSetup
  extend ActiveSupport::Concern

  included do
    helper_method :in_initial_setup_state?
  end

  def in_initial_setup_state?
    return false unless User.limit(2).count == 1 # Count as much 2 to know if we have exactly one

    user = User.admins.last

    return false unless user && user.require_password_creation_for_web?

    true
  end
end
