module EE
  module Groups
    module UpdateService
      def execute
        raise NotImplementedError unless defined?(super)

        super.tap { |success| log_audit_event if success }
      end

      private

      def log_audit_event
        EE::Audit::GroupChangesAuditor.new(current_user, group).execute
      end
    end
  end
end
