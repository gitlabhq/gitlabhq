# frozen_string_literal: true

module Gitlab
  module GithubImport
    # Module that provides methods shared by the various workers used for
    # importing GitHub projects.
    module ReschedulingMethods
      # project_id - The ID of the GitLab project to import the note into.
      # hash - A Hash containing the details of the GitHub object to imoprt.
      # notify_key - The Redis key to notify upon completion, if any.
      def perform(project_id, hash, notify_key = nil)
        project = Project.find_by(id: project_id)

        return notify_waiter(notify_key) unless project

        client = GithubImport.new_client_for(project, parallel: true)

        if try_import(project, client, hash)
          notify_waiter(notify_key)
        else
          # In the event of hitting the rate limit we want to reschedule the job
          # so its retried after our rate limit has been reset.
          self.class
            .perform_in(client.rate_limit_resets_in, project.id, hash, notify_key)
        end
      end

      def try_import(*args)
        import(*args)
        true
      rescue RateLimitError
        false
      end

      def notify_waiter(key = nil)
        JobWaiter.notify(key, jid) if key
      end
    end
  end
end
