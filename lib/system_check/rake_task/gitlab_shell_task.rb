# frozen_string_literal: true

module SystemCheck
  module RakeTask
    # Used by gitlab:gitlab_shell:check rake task
    class GitlabShellTask
      extend RakeTaskHelpers

      def self.name
        'GitLab Shell'
      end

      def self.checks
        [SystemCheck::GitlabShellCheck]
      end
    end
  end
end
