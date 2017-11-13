module Emails
  class ConfirmService < ::Emails::BaseService
    def execute(email)
      email.resend_confirmation_instructions
    end
  end
end
