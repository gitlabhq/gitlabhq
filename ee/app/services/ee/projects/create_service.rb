module EE
  module Projects
    module CreateService
      def execute
        raise NotImplementedError unless defined?(super)

        limit = params.delete(:repository_size_limit)
        mirror = params.delete(:mirror)
        mirror_user_id = params.delete(:mirror_user_id)
        mirror_trigger_builds = params.delete(:mirror_trigger_builds)

        project = super do |project|
          # Repository size limit comes as MB from the view
          project.repository_size_limit = ::Gitlab::Utils.try_megabytes_to_bytes(limit) if limit

          if mirror && project.feature_available?(:repository_mirrors)
            project.mirror = mirror unless mirror.nil?
            project.mirror_trigger_builds = mirror_trigger_builds unless mirror_trigger_builds.nil?
            project.mirror_user_id = mirror_user_id
          end
        end

        log_geo_event(project) if project&.persisted?

        project
      end

      private

      def log_geo_event(project)
        ::Geo::RepositoryCreatedEventStore.new(project).create
      end

      def after_create_actions
        raise NotImplementedError unless defined?(super)

        super

        create_predefined_push_rule

        @project.group&.refresh_members_authorized_projects
      end

      def create_predefined_push_rule
        return unless project.feature_available?(:push_rules)

        predefined_push_rule = PushRule.find_by(is_sample: true)

        if predefined_push_rule
          push_rule = predefined_push_rule.dup.tap { |gh| gh.is_sample = false }
          project.push_rule = push_rule
        end
      end
    end
  end
end
