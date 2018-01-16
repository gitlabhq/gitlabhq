module EE
  module Projects
    module GroupLinks
      module DestroyService
        extend ::Gitlab::Utils::Override

        override :execute
        def execute(group_link)
          super.tap { |link| log_audit_event(link) if link && !link&.persisted? }
        end

        private

        def log_audit_event(group_link)
          ::AuditEventService.new(
            current_user,
            group_link.group,
            action: :destroy
          ).for_project_group_link(group_link).security_event
        end
      end
    end
  end
end
