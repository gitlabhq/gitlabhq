# frozen_string_literal: true

module SystemCheck
  module RakeTask
    # Used by gitlab:check rake task
    class GitlabTask
      extend RakeTaskHelpers

      def self.name
        'GitLab'
      end

      def self.manual_run_checks!
        start_checking("#{name} subtasks")

        subtasks.each(&:run_checks!)

        finished_checking("#{name} subtasks")
      end

      def self.subtasks
        [
          SystemCheck::RakeTask::GitlabShellTask,
          SystemCheck::RakeTask::GitalyTask,
          SystemCheck::RakeTask::SidekiqTask,
          SystemCheck::RakeTask::IncomingEmailTask,
          SystemCheck::RakeTask::LdapTask,
          SystemCheck::RakeTask::AppTask
        ]
      end
    end
  end
end

SystemCheck::RakeTask::GitlabTask.prepend_mod_with('SystemCheck::RakeTask::GitlabTask')
