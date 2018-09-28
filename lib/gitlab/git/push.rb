# frozen_string_literal: true

module Gitlab
  module Git
    class Push
      def initialize(project, oldrev, newrev, ref)
        @project, @oldrev, @newrev = project, oldrev, newrev
        @repository = project.repository
        @branch_name = Gitlab::Git.ref_name(ref)
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
    end
  end
end
