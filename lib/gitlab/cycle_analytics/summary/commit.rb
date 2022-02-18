# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    module Summary
      class Commit < Base
        def identifier
          :commits
        end

        def title
          n_('Commit', 'Commits', value.to_i)
        end

        def value
          @value ||= commits_count ? Value::PrettyNumeric.new(commits_count) : Value::None.new
        end

        private

        # Don't use the `Gitlab::Git::Repository#log` method, because it enforces
        # a limit. Since we need a commit count, we _can't_ enforce a limit, so
        # the easiest way forward is to replicate the relevant portions of the
        # `log` function here.
        def commits_count
          return unless ref

          @commits_count ||= gitaly_commit_client.commit_count(ref, after: @options[:from], before: @options[:to])
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
