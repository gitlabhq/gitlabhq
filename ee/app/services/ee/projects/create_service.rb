module EE
  module Projects
    module CreateService
      def execute
        raise NotImplementedError unless defined?(super)

        mirror = params.delete(:mirror)
        mirror_user_id = params.delete(:mirror_user_id)
        mirror_trigger_builds = params.delete(:mirror_trigger_builds)

        super do |project|
          if mirror && project.feature_available?(:repository_mirrors)
            project.mirror = mirror unless mirror.nil?
            project.mirror_trigger_builds = mirror_trigger_builds unless mirror_trigger_builds.nil?
            project.mirror_user_id = mirror_user_id
          end
        end
      end

      private

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
