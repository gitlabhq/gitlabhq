# frozen_string_literal: true

module Emails
  class CreateService < ::Emails::BaseService
    def execute(extra_params = {})
      skip_confirmation = params.delete(:skip_confirmation)

      user.emails.create(params.merge(extra_params)).tap do |email|
        email&.confirm if skip_confirmation && current_user.admin?
        notification_service.new_email_address_added(user, email.email) if email.persisted? && !email.user_primary_email?
      end
    end
  end
end

Emails::CreateService.prepend_mod_with('Emails::CreateService')
