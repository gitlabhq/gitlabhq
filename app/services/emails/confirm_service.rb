module Emails
  class ConfirmService < ::Emails::BaseService
    def execute
      Email.find_by_email!(@email).resend_confirmation_instructions
    end
  end
end
