module Gitlab
  module CycleAnalytics
    module Summary
      class Commit < Base
        def title
          n_('Commit', 'Commits', value)
        end

        def value
          @value ||= count_commits
        end

        private

        # Don't use the `Gitlab::Git::Repository#log` method, because it enforces
        # a limit. Since we need a commit count, we _can't_ enforce a limit, so
        # the easiest way forward is to replicate the relevant portions of the
        # `log` function here.
        def count_commits
          return unless ref

          gitaly_commit_client.commit_count(ref, after: @from)
        end

        def gitaly_commit_client
          Gitlab::GitalyClient::CommitService.new(@project.repository.raw_repository)
        end

        def ref
          @ref ||= @project.default_branch.presence
        end
      end
    end
  end
end
