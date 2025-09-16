# frozen_string_literal: true

require 'openssl'
require 'digest'

module Gitlab
  module X509
    class Commit < Gitlab::Repositories::BaseSignedCommit
      def signature
        return @signature if @signature

        cached_signature = lazy_signature&.itself

        # only update the committer email without re verifing the cached signature
        return @signature = update_committer_email!(cached_signature) if should_update_signature?(cached_signature)

        return @signature = cached_signature if cached_signature.present?

        @signature = create_cached_signature!
      end

      private

      def update_committer_email!(cached_signature)
        cached_signature.update!(committer_email: committer_email)
        @signature = cached_signature
      end

      def committer_email_missing?(cached_signature)
        cached_signature.committer_email.nil? && committer_email.present?
      end

      def should_update_signature?(cached_signature)
        cached_signature.present? &&
          committer_email_missing?(cached_signature) &&
          check_for_mailmapped_commit_emails?
      end

      def committer_email
        @signature_data.itself ? @signature_data[:committer_email] : nil
      end
      strong_memoize_attr :committer_email

      def signature_class
        CommitSignatures::X509CommitSignature
      end

      def attributes
        return if @commit.sha.nil? || @commit.project.nil?

        signature = X509::Signature.new(signature_text, signed_text, @commit.committer_email, @commit.created_at)

        return if signature.verified_signature.nil? || signature.x509_certificate.nil?

        {
          commit_sha: @commit.sha,
          project: @commit.project,
          x509_certificate_id: signature.x509_certificate.id,
          verification_status: signature.verification_status
        }.tap do |attrs|
          attrs[:committer_email] = @commit.committer_email if check_for_mailmapped_commit_emails?
        end
      end

      def check_for_mailmapped_commit_emails?
        Feature.enabled?(:check_for_mailmapped_commit_emails, @commit.project)
      end
    end
  end
end
