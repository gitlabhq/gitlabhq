# frozen_string_literal: true

module Gitlab
  module Git
    class Push
      include Gitlab::Utils::StrongMemoize

      attr_reader :ref, :oldrev, :newrev

      def initialize(project, oldrev, newrev, ref)
        @project = project
        @oldrev = oldrev.presence || Gitlab::Git::SHA1_BLANK_SHA
        @newrev = newrev.presence || Gitlab::Git::SHA1_BLANK_SHA
        @ref = ref
      end

      def branch_name
        strong_memoize(:branch_name) do
          Gitlab::Git.branch_name(@ref)
        end
      end

      def branch_added?
        Gitlab::Git.blank_ref?(@oldrev)
      end

      def branch_removed?
        Gitlab::Git.blank_ref?(@newrev)
      end

      def branch_updated?
        branch_push? && !branch_added? && !branch_removed?
      end

      def force_push?
        strong_memoize(:force_push) do
          Gitlab::Checks::ForcePush.force_push?(@project, @oldrev, @newrev)
        end
      end

      def branch_push?
        strong_memoize(:branch_push) do
          Gitlab::Git.branch_ref?(@ref)
        end
      end

      def modified_paths
        unless branch_updated?
          raise ArgumentError, 'Unable to calculate modified paths!'
        end

        strong_memoize(:modified_paths) do
          @project.repository.diff_stats(@oldrev, @newrev).paths
        end
      end
    end
  end
end
