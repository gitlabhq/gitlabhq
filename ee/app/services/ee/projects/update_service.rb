module EE
  module Projects
    module UpdateService
      def execute
        raise NotImplementedError unless defined?(super)

        unless project.feature_available?(:repository_mirrors)
          params.delete(:mirror)
          params.delete(:mirror_user_id)
          params.delete(:mirror_trigger_builds)
        end

        result = super

        log_audit_events if result[:status] == :success

        result
      end

      private

      def log_audit_events
        EE::Audit::ProjectChangesAuditor.new(current_user, project).execute
      end
    end
  end
end
