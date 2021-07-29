# frozen_string_literal: true
require 'openssl'
require 'digest'

module Gitlab
  module X509
    class Commit < Gitlab::SignedCommit
      def signature
        super

        return @signature if @signature

        cached_signature = lazy_signature&.itself
        return @signature = cached_signature if cached_signature.present?

        @signature = create_cached_signature!
      end

      def update_signature!(cached_signature)
        cached_signature.update!(attributes)
        @signature = cached_signature
      end

      private

      def lazy_signature
        BatchLoader.for(@commit.sha).batch do |shas, loader|
          X509CommitSignature.by_commit_sha(shas).each do |signature|
            loader.call(signature.commit_sha, signature)
          end
        end
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

      def create_cached_signature!
        return if attributes.nil?

        return X509CommitSignature.new(attributes) if Gitlab::Database.main.read_only?

        X509CommitSignature.safe_create!(attributes)
      end
    end
  end
end
