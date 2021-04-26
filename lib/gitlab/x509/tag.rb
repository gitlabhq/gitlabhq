# frozen_string_literal: true
require 'openssl'
require 'digest'

module Gitlab
  module X509
    class Tag
      include Gitlab::Utils::StrongMemoize

      def initialize(raw_tag)
        @raw_tag = raw_tag
      end

      def signature
        signature = X509::Signature.new(signature_text, signed_text, @raw_tag.tagger.email, Time.at(@raw_tag.tagger.date.seconds))

        return if signature.verified_signature.nil?

        signature
      end

      private

      def signature_text
        @raw_tag.message.slice(@raw_tag.message.index("-----BEGIN SIGNED MESSAGE-----")..-1)
      rescue StandardError
        nil
      end

      def signed_text
        # signed text is reconstructed as long as there is no specific gitaly function
        %{object #{@raw_tag.target_commit.id}
type commit
tag #{@raw_tag.name}
tagger #{@raw_tag.tagger.name} <#{@raw_tag.tagger.email}> #{@raw_tag.tagger.date.seconds} #{@raw_tag.tagger.timezone}

#{@raw_tag.message.gsub(/-----BEGIN SIGNED MESSAGE-----(.*)-----END SIGNED MESSAGE-----/m, "")}}
      end
    end
  end
end
