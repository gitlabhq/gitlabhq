module EE
  module Groups
    module CreateService
      def execute
        raise NotImplementedError unless defined?(super)

        super.tap { |group| log_audit_event if group&.persisted? }
      end

      private

      def log_audit_event
        ::AuditEventService.new(
          current_user,
          group,
          action: :create
        ).for_group.security_event
      end
    end
  end
end
