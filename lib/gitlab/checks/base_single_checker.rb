# frozen_string_literal: true

module Gitlab
  module Checks
    class BaseSingleChecker < BaseChecker
      attr_reader :change_access

      delegate(*SingleChangeAccess::ATTRIBUTES, :branch_ref?, :tag_ref?, to: :change_access)

      def initialize(change_access)
        @change_access = change_access
      end

      private

      def creation?
        Gitlab::Git.blank_ref?(oldrev)
      end

      def deletion?
        Gitlab::Git.blank_ref?(newrev)
      end

      def update?
        !creation? && !deletion?
      end

      def tag_exists?
        project.repository.tag_exists?(tag_name)
      end

      # If a commit is created from Web and signed by GitLab, we can skip the committer check because it's equal to
      # GitLab <noreply@gitlab.com>
      def signed_by_gitlab?(commit)
        return false unless ::Feature.enabled?(:skip_committer_email_check, project)
        return false unless updated_from_web? && commit.has_signature?

        commit_signatures[commit.id][:signer] == :SIGNER_SYSTEM
      end

      def commit_signatures
        ::Gitlab::Git::Commit.batch_signature_extraction(project.repository, commits.map(&:id))
      end
      strong_memoize_attr :commit_signatures
    end
  end
end
