# Call out to the `git rev-list` command

module Gitlab
  module Git
    class RevList
      include ActiveModel::Validations

      validates :env, git_environment_variables: true

      attr_reader :project, :env

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
        if self.valid?
          Gitlab::Popen.popen(@args, nil, @env.slice(*allowed_environment_variables))
        else
          Gitlab::Popen.popen(@args)
        end
      end

      private

      def allowed_environment_variables
        %w(GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_OBJECT_DIRECTORY)
      end
    end
  end
end
