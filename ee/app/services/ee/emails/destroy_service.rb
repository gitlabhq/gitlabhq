module EE
  module Emails
    module DestroyService
      include ::EE::Emails::BaseService

      def execute
        super.tap do
          log_audit_event(action: :destroy)
        end
      end
    end
  end
end
