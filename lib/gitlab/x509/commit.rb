# frozen_string_literal: true
require 'openssl'
require 'digest'

module Gitlab
  module X509
    class Commit < Gitlab::SignedCommit
      private

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
        }
      end
    end
  end
end
