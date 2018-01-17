module EE
  module Groups
    module UpdateService
      extend ::Gitlab::Utils::Override

      override :execute
      def execute
        super.tap { |success| log_audit_event if success }
      end

      private

      def log_audit_event
        EE::Audit::GroupChangesAuditor.new(current_user, group).execute
      end
    end
  end
end
