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

        # We need to update the cache if there is no user for a verified system commit.
        # This is because of the introduction of mailmap. See https://gitlab.com/gitlab-org/gitlab/-/issues/425042#note_1997022896.
        if cached_signature.present? && verified_system_user_missing?(cached_signature) && Feature.enabled?(
          :check_for_mailmapped_commit_emails, @commit.project)
          return @signature = update_signature!(cached_signature)
        end

        return @signature = cached_signature if cached_signature.present?

        @signature = create_cached_signature!
      end

      def verified_system_user_missing?(cached_signature)
        cached_signature.verified_system? && cached_signature.user.nil? && author_email.present?
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

      def author_email
        @signature_data.itself ? @signature_data[:author_email] : nil
      end
      strong_memoize_attr :author_email

      private

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
