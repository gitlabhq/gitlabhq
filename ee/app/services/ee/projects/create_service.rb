module EE
  module Projects
    module CreateService
      extend ::Gitlab::Utils::Override

      override :execute
      def execute
        limit = params.delete(:repository_size_limit)
        mirror = params.delete(:mirror)
        mirror_user_id = params.delete(:mirror_user_id)
        mirror_trigger_builds = params.delete(:mirror_trigger_builds)
        ci_cd_only = ::Gitlab::Utils.to_boolean(params.delete(:ci_cd_only))

        project = super do |project|
          # Repository size limit comes as MB from the view
          project.repository_size_limit = ::Gitlab::Utils.try_megabytes_to_bytes(limit) if limit

          if mirror && project.feature_available?(:repository_mirrors)
            project.mirror = mirror unless mirror.nil?
            project.mirror_trigger_builds = mirror_trigger_builds unless mirror_trigger_builds.nil?
            project.mirror_user_id = mirror_user_id
          end
        end

        if project&.persisted?
          setup_ci_cd_project if ci_cd_only

          log_geo_event(project)
          log_audit_event(project)
        end

        project
      end

      private

      def log_geo_event(project)
        ::Geo::RepositoryCreatedEventStore.new(project).create
      end

      override :after_create_actions
      def after_create_actions
        super

        create_predefined_push_rule

        project.group&.refresh_members_authorized_projects
      end

      def create_predefined_push_rule
        return unless project.feature_available?(:push_rules)

        predefined_push_rule = PushRule.find_by(is_sample: true)

        if predefined_push_rule
          push_rule = predefined_push_rule.dup.tap { |gh| gh.is_sample = false }
          project.push_rule = push_rule
        end
      end

      def setup_ci_cd_project
        return unless ::License.feature_available?(:ci_cd_projects)

        ::CiCd::SetupProject.new(project, current_user).execute
      end

      def log_audit_event(project)
        ::AuditEventService.new(
          current_user,
          project,
          action: :create
        ).for_project.security_event
      end
    end
  end
end
