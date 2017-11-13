module Gitlab
  module LegacyGithubImport
    class BranchFormatter < BaseFormatter
      delegate :repo, :sha, :ref, to: :raw_data

      def exists?
        branch_exists? && commit_exists?
      end

      def valid?
        sha.present? && ref.present?
      end

      def user
        raw_data.user&.login || 'unknown'
      end

      def short_sha
        Commit.truncate_sha(sha)
      end

      private

      def branch_exists?
        project.repository.branch_exists?(ref)
      end

      def commit_exists?
        project.repository.branch_names_contains(sha).include?(ref)
      end

      def short_id
        sha.to_s[0..7]
      end
    end
  end
end
