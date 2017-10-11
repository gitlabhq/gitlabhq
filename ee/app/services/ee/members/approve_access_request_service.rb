module EE
  module Members
    module ApproveAccessRequestService
      def after_execute(member:, **opts)
        super

        # Don't log this event in the case of a mass-approval, e.g. LDAP group-sync
        log_audit_event(member: member) unless opts[:ldap]
      end

      private

      def log_audit_event(member:)
        ::AuditEventService.new(
          current_user,
          source,
          action: :create
        ).for_member(member).security_event
      end
    end
  end
end
