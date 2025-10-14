# frozen_string_literal: true

module Gitlab
  module Ssh
    class Tag < Gitlab::SignedTag
      include Gitlab::Utils::StrongMemoize

      def signature
        super

        Ssh::Signature.new(signature_text, signed_text, nil, tag_commit)
      end
      strong_memoize_attr :signature

      private

      def tag_commit
        Struct.new(:committer_email, :project).new(@tag.user_email, @repository.container)
      end
    end
  end
end
