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

        def commits_count
          return unless ref

          @commits_count ||= @project.repository.count_commits(
            ref: ref,
            after: @options[:from],
            before: @options[:to]
          )
        end

        def ref
          @ref ||= @project.default_branch.presence
        end
      end
    end
  end
end
