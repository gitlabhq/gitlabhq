# frozen_string_literal: true

module API
  module Entities
    class CommitSignature < Grape::Entity
      expose :signature_type

      expose :signature, merge: true do |commit, options|
        if commit.signature.is_a?(GpgSignature) || commit.raw_commit_from_rugged?
          ::API::Entities::GpgCommitSignature.represent commit_signature(commit), options
        elsif commit.signature.is_a?(X509CommitSignature)
          ::API::Entities::X509Signature.represent commit.signature, options
        end
      end

      expose :commit_source do |commit, _|
        commit.raw_commit_from_rugged? ? "rugged" : "gitaly"
      end

      private

      def commit_signature(commit)
        if commit.raw_commit_from_rugged?
          commit.gpg_commit.signature
        else
          commit.signature
        end
      end
    end
  end
end
