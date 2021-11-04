# frozen_string_literal: true

module Emails
  class DestroyService < ::Emails::BaseService
    def execute(email)
      raise StandardError, 'Cannot delete primary email' if email.user_primary_email?

      email.destroy && update_secondary_emails!(email.email)
    end

    private

    def update_secondary_emails!(deleted_email)
      result = ::Users::UpdateService.new(@current_user, user: @user).execute do |user|
        user.unset_secondary_emails_matching_deleted_email!(deleted_email)
      end

      result[:status] == :success
    end
  end
end

Emails::DestroyService.prepend_mod_with('Emails::DestroyService')
