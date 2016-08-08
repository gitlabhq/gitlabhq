module Gitlab
  module GithubImport
    class BranchFormatter < BaseFormatter
      delegate :repo, :sha, :ref, to: :raw_data

      def exists?
        branch_exists? && commit_exists?
      end

      def valid?
        repo.present?
      end

      private

      def branch_exists?
        project.repository.branch_exists?(ref)
      end

      def commit_exists?
        project.repository.commit(sha).present?
      end

      def short_id
        sha.to_s[0..7]
      end
    end
  end
end
