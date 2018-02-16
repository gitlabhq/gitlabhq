module EE
  module Members
    module DestroyService
      def after_execute(member:)
        super

        log_audit_event(member: member)
      end

      private

      def log_audit_event(member:)
        ::AuditEventService.new(
          current_user,
          member.source,
          action: :destroy
        ).for_member(member).security_event
      end
    end
  end
end
