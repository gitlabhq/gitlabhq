module Gitlab
  module CycleAnalytics
    module Summary
      class Commit < Base
        def title
          n_('Commit', 'Commits', value)
        end

        def value
          Gitlab::GitalyClient::StorageSettings.allow_disk_access do
            @value ||= count_commits
          end
        end

        private

        # Don't use the `Gitlab::Git::Repository#log` method, because it enforces
        # a limit. Since we need a commit count, we _can't_ enforce a limit, so
        # the easiest way forward is to replicate the relevant portions of the
        # `log` function here.
        def count_commits
          return unless ref

          repository = @project.repository.raw_repository
          sha = @project.repository.commit(ref).sha

          cmd = %W(git --git-dir=#{repository.path} log)
          cmd << '--format=%H'
          cmd << "--after=#{@from.iso8601}"
          cmd << sha

          output, status = Gitlab::Popen.popen(cmd)

          raise IOError, output unless status.zero?

          output.lines.count
        end

        def ref
          @ref ||= @project.default_branch.presence
        end
      end
    end
  end
end
