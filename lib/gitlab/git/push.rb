# frozen_string_literal: true

module Gitlab
  module Git
    class Push
      attr_reader :oldrev, :newrev

      def initialize(project, oldrev, newrev, ref)
        @project = project
        @oldrev = oldrev
        @newrev = newrev
        @ref = ref
      end

      def branch_name
        @branch_name ||= Gitlab::Git.ref_name(@ref)
      end

      def branch_added?
        Gitlab::Git.blank_ref?(@oldrev)
      end

      def branch_removed?
        Gitlab::Git.blank_ref?(@newrev)
      end

      def force_push?
        Gitlab::Checks::ForcePush.force_push?(@project, @oldrev, @newrev)
      end

      def branch_push?
        Gitlab::Git.branch_ref?(@ref)
      end
    end
  end
end
