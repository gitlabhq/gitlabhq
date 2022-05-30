# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Background migration for fixing merge_request_diff_commit rows that don't
    # have committer/author details due to
    # https://gitlab.com/gitlab-org/gitlab/-/issues/344080.
    class FixMergeRequestDiffCommitUsers
      BATCH_SIZE = 100

      def initialize
        @commits = {}
        @users = {}
      end

      def perform(project_id)
        # No-op, see https://gitlab.com/gitlab-org/gitlab/-/issues/344540
      end
    end
  end
end
