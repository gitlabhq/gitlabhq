# frozen_string_literal: true

module Gitlab
  class SignedTag
    include Gitlab::Utils::StrongMemoize

    def initialize(repository, tag)
      @repository = repository
      @tag = tag

      if Feature.enabled?(:get_tag_signatures)
        @signature_data = Gitlab::Git::Tag.extract_signature_lazily(repository, tag.id) if repository
      else
        @signature_data = [signature_text_of_message.b, signed_text_of_message.b]
      end
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

    private

    def signature_text_of_message
      @tag.message.slice(@tag.message.index("-----BEGIN SIGNED MESSAGE-----")..-1)
    rescue StandardError
      nil
    end

    def signed_text_of_message
      %{object #{@tag.target_commit.id}
type commit
tag #{@tag.name}
tagger #{@tag.tagger.name} <#{@tag.tagger.email}> #{@tag.tagger.date.seconds} #{@tag.tagger.timezone}

#{@tag.message.gsub(/-----BEGIN SIGNED MESSAGE-----(.*)-----END SIGNED MESSAGE-----/m, "")}}
    end
  end
end
