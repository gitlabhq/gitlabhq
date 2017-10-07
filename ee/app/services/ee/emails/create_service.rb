module EE
  module Emails
    module CreateService
      include ::EE::Emails::BaseService

      def execute(*args, &blk)
        super.tap do |email|
          log_audit_event(action: :create) if email.persisted?
        end
      end
    end
  end
end
