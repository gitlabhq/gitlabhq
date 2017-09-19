module EE
  module Emails
    module CreateService
      include EE::Emails::BaseService

      def execute
        email = super

        log_audit_event(action: :create) if email.persisted?

        email
      end
    end
  end
end
