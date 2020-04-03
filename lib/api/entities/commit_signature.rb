# frozen_string_literal: true

module API
  module Entities
    class CommitSignature < Grape::Entity
      expose :signature_type
      expose :signature, merge: true do |commit, options|
        if commit.signature.is_a?(GpgSignature)
          ::API::Entities::GpgCommitSignature.represent commit.signature, options
        elsif commit.signature.is_a?(X509CommitSignature)
          ::API::Entities::X509Signature.represent commit.signature, options
        end
      end
    end
  end
end
