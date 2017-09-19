module Emails
  class CreateService < ::Emails::BaseService
    def execute
      email = @user.emails.create(email: @email)

      log_audit_event(action: :create)

      email
    end
  end
end
