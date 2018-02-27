module EE
  module Members
    module CreateService
      def after_execute(member:)
        super

        log_audit_event(member: member)
      end

      private

      def log_audit_event(member:)
        ::AuditEventService.new(
          current_user,
          member.source,
          action: :create
        ).for_member(member).security_event
      end
    end
  end
end
