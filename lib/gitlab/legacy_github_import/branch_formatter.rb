# frozen_string_literal: true

module Gitlab
  module LegacyGithubImport
    class BranchFormatter < BaseFormatter
      def repo
        raw_data[:repo]
      end

      def sha
        raw_data[:sha]
      end

      def ref
        raw_data[:ref]
      end

      def exists?
        branch_exists? && commit_exists?
      end

      def valid?
        sha.present? && ref.present?
      end

      def user
        raw_data.dig(:user, :login) || 'unknown'
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
