module EE
  module Members
    module ApproveAccessRequestService
      def after_execute(member:, skip_log_audit_event: false)
        super

        log_audit_event(member: member) unless skip_log_audit_event
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
