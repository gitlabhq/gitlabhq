module EE
  module Groups
    module CreateService
      extend ::Gitlab::Utils::Override

      override :execute
      def execute
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
