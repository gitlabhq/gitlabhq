# frozen_string_literal: true

module Emails
  class DestroyService < ::Emails::BaseService
    def execute(email)
      email.destroy && update_secondary_emails!
    end

    private

    def update_secondary_emails!
      result = ::Users::UpdateService.new(@current_user, user: @user).execute do |user|
        user.update_secondary_emails!
      end

      result[:status] == :success
    end
  end
end

Emails::DestroyService.prepend_mod_with('Emails::DestroyService')
