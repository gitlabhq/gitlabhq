module EE
  module Groups
    module DestroyService
      def execute
        raise NotImplementedError unless defined?(super)

        super.tap { |group| log_audit_event unless group&.persisted? }
      end

      private

      def log_audit_event
        ::AuditEventService.new(
          current_user,
          group,
          action: :destroy
        ).for_group.security_event
      end
    end
  end
end
