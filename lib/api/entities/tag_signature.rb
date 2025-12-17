# frozen_string_literal: true

module API
  module Entities
    class TagSignature < Grape::Entity
      expose :signature_type, documentation: { type: 'String', example: 'PGP' }

      expose :signature, merge: true do |tag|
        ::API::Entities::X509Signature.represent tag.signature if tag.signature_type == :X509
      end
    end
  end
end
