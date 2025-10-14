# frozen_string_literal: true

module Gitlab
  module Repositories
    class BaseSignedCommit
      include Gitlab::Utils::StrongMemoize

      delegate :id, to: :@commit

      def initialize(commit)
        @commit = commit

        if commit.project
          repo = commit.project.repository.raw_repository
          @signature_data = Gitlab::Git::Commit.extract_signature_lazily(repo, commit.sha || commit.id)
        end

        lazy_signature
      end

      def signature
        return @signature if @signature

        cached_signature = lazy_signature&.itself

        if cached_signature.present?
          # only update the committer email without re verifying the cached signature
          return @signature = update_committer_email!(cached_signature) if should_update_signature?(cached_signature)

          return @signature = cached_signature
        end

        @signature = create_cached_signature!
      end

      def update_signature!(cached_signature)
        cached_signature.update!(attributes)
        @signature = cached_signature
      end

      def signature_text
        @signature_data.itself ? @signature_data[:signature] : nil
      end
      strong_memoize_attr :signature_text

      def signed_text
        @signature_data.itself ? @signature_data[:signed_text] : nil
      end
      strong_memoize_attr :signed_text

      def signer
        @signature_data.itself ? @signature_data[:signer] : nil
      end
      strong_memoize_attr :signer

      def committer_email
        @signature_data.itself ? @signature_data[:committer_email] : nil
      end
      strong_memoize_attr :committer_email

      private

      def update_committer_email!(cached_signature)
        cached_signature.update!(committer_email: committer_email)
        @signature = cached_signature
      end

      def should_update_signature?(cached_signature)
        check_for_mailmapped_commit_emails? &&
          verified_system_or_x509?(cached_signature) &&
          committer_email_missing?(cached_signature)
      end

      def committer_email_missing?(cached_signature)
        # cached_signature.committer_email referring to the persisted commited email in the db.
        # committer_email.present? is checking for a committer email in the response from
        # GetCommitSignaturesResponse rpc.
        cached_signature.committer_email.nil? && committer_email.present?
      end

      def verified_system_or_x509?(cached_signature)
        cached_signature.verified_system? || cached_signature.x509?
      end

      def check_for_mailmapped_commit_emails?
        Feature.enabled?(:check_for_mailmapped_commit_emails, @commit.project)
      end

      def signature_class
        raise NotImplementedError, '`signature_class` must be implemented by subclass`'
      end

      def lazy_signature
        BatchLoader.for(@commit.sha).batch do |shas, loader|
          signature_class.by_commit_sha(shas).each do |signature|
            loader.call(signature.commit_sha, signature)
          end
        end
      end

      def create_cached_signature!
        return if attributes.nil?

        return signature_class.new(attributes) if Gitlab::Database.read_only?

        signature_class.safe_create!(attributes)
      end
    end
  end
end
