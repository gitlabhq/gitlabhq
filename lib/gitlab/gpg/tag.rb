# frozen_string_literal: true

module Gitlab
  module Gpg
    class Tag < Gitlab::SignedTag
      include Gitlab::Utils::StrongMemoize

      def signature
        super

        Gpg::Signature.new(signature_text, signed_text, nil, @tag.user_email)
      end
      strong_memoize_attr :signature
    end
  end
end
