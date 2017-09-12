module Emails
  class CreateService < ::Emails::BaseService
    def execute
      @user.emails.create(email: @email)

      log_audit_event(action: :create)
    end
  end
end
