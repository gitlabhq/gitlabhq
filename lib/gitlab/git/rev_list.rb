# Call out to the `git rev-list` command

module Gitlab
  module Git
    class RevList
      def initialize(oldrev, newrev, project:, env: nil)
        @args = [Gitlab.config.git.bin_path,
                 "--git-dir=#{project.repository.path_to_repo}",
                 "rev-list",
                 "--max-count=1",
                 oldrev,
                 "^#{newrev}"]

        @env = env.slice(*allowed_environment_variables)
      end

      def execute
        Gitlab::Popen.popen(@args, nil, @env.slice(*allowed_environment_variables))
      end

      private

      def allowed_environment_variables
        %w(GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_OBJECT_DIRECTORY)
      end
    end
  end
end
