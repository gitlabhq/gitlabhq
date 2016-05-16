module Gitlab
  module GithubImport
    class BranchFormatter < BaseFormatter
      delegate :repo, :sha, :ref, to: :raw_data

      def exists?
        project.repository.branch_exists?(ref)
      end

      def name
        @name ||= exists? ? ref : "#{ref}-#{short_id}"
      end

      def valid?
        repo.present?
      end

      def valid?
        repo.present?
      end

      private

      def short_id
        sha.to_s[0..7]
      end
    end
  end
end
