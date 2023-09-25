# frozen_string_literal: true

module Authorizations
  class NotificationService
    include BaseServiceUtility

    attr_reader :current_user

    def initialize(current_user)
      @current_user = current_user
    end

    # EE would override and use `request` arg
    def execute
      notification_service.application_authorized(current_user)
    end
  end
end

Authorizations::NotificationService.prepend_mod_with('Authorizaions::NotificationService')
