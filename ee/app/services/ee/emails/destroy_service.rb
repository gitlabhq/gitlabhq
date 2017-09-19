module EE
  module Emails
    module DestroyService
      include EE::Emails::BaseService

      def execute
        result = super

        log_audit_event(action: :destroy)

        result
      end
    end
  end
end
