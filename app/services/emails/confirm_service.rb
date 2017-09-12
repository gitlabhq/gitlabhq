module Emails
  class ConfirmService < ::Emails::BaseService
    def execute(email_record)
      email_record.resend_confirmation_instructions
    end
  end
end
