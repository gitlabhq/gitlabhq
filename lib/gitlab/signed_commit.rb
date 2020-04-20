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
      return unless @commit.has_signature?
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
  end
end
