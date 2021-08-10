# frozen_string_literal: true
require 'openssl'
require 'digest'

module Gitlab
  module X509
    class Tag < Gitlab::SignedTag
      include Gitlab::Utils::StrongMemoize

      def signature
        strong_memoize(:signature) do
          super

          signature = X509::Signature.new(signature_text, signed_text, @tag.tagger.email, Time.at(@tag.tagger.date.seconds))
          signature unless signature.verified_signature.nil?
        end
      end
    end
  end
end
