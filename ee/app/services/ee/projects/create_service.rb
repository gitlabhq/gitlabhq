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
            project.mirror = mirror
            project.mirror_user_id = mirror_user_id
            project.mirror_trigger_builds = mirror_trigger_builds
          end
        end
      end
    end
  end
end
