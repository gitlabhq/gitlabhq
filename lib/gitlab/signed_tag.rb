# frozen_string_literal: true

module Gitlab
  class SignedTag
    include Gitlab::Utils::StrongMemoize

    def initialize(repository, tag)
      @repository = repository
      @tag = tag
      @signature_data = Gitlab::Git::Tag.extract_signature_lazily(repository, tag.id) if repository
    end

    def signature
      return unless @tag.has_signature?
    end

    def signature_text
      @signature_data&.fetch(0)
    end

    def signed_text
      @signature_data&.fetch(1)
    end
  end
end
