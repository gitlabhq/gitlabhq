module Gitlab
  module Git
    class RevList
      attr_reader :project, :env

      ALLOWED_VARIABLES = %w[GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES].freeze

      def initialize(oldrev, newrev, project:, env: nil)
        @project = project
        @env = env.presence || {}
        @args = [Gitlab.config.git.bin_path,
                 "--git-dir=#{project.repository.path_to_repo}",
                 "rev-list",
                 "--max-count=1",
                 oldrev,
                 "^#{newrev}"]
      end

      def execute
        Gitlab::Popen.popen(@args, nil, parse_environment_variables)
      end

      def valid?
        environment_variables.all? do |(name, value)|
          value.start_with?(project.repository.path_to_repo)
        end
      end

      private

      def parse_environment_variables
        return {} unless valid?

        environment_variables
      end

      def environment_variables
        @environment_variables ||= env.slice(*ALLOWED_VARIABLES)
      end
    end
  end
end
