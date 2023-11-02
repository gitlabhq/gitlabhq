# frozen_string_literal: true

module API
  module Entities
    class CommitSignature < Grape::Entity
      expose :signature_type, documentation: { type: 'string', example: 'PGP' }

      expose :signature, merge: true do |commit, options|
        case commit.signature
        when ::CommitSignatures::GpgSignature
          ::API::Entities::GpgCommitSignature.represent commit_signature(commit), options
        when ::CommitSignatures::X509CommitSignature
          ::API::Entities::X509Signature.represent commit.signature, options
        when ::CommitSignatures::SshSignature
          ::API::Entities::SshSignature.represent(commit.signature, options)
        end
      end

      expose :commit_source, documentation: { type: 'string', example: 'gitaly' } do |_commit, _|
        "gitaly"
      end

      private

      def commit_signature(commit)
        commit.signature
      end
    end
  end
end
