# frozen_string_literal: true

# This concern can be included in devise controllers to skip showing an "already signed in"
# warning on registrations and logins
module SkipsAlreadySignedInMessage
  extend ActiveSupport::Concern

  included do
    # replaced with :require_no_authentication_without_flash
    # rubocop: disable Rails/LexicallyScopedActionFilter
    # The actions are defined in Devise
    skip_before_action :require_no_authentication, only: [:new, :create]
    before_action :require_no_authentication_without_flash, only: [:new, :create]
    # rubocop: enable Rails/LexicallyScopedActionFilter
  end

  def require_no_authentication_without_flash
    require_no_authentication

    return unless flash[:alert] == I18n.t('devise.failure.already_authenticated')

    flash[:alert] = nil
  end
end
