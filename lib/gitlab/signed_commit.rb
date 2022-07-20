# frozen_string_literal: true

module Gitlab
  class SignedCommit
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

      return @signature = cached_signature if cached_signature.present?

      @signature = create_cached_signature!
    end

    def update_signature!(cached_signature)
      cached_signature.update!(attributes)
      @signature = cached_signature
    end

    def signature_text
      strong_memoize(:signature_text) do
        @signature_data.itself ? @signature_data[0] : nil
      end
    end

    def signed_text
      strong_memoize(:signed_text) do
        @signature_data.itself ? @signature_data[1] : nil
      end
    end

    private

    def signature_class
      raise NotImplementedError, '`signature_class` must be implmented by subclass`'
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
