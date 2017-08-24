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

        super
      end
    end
  end
end
