# frozen_string_literal: true

module Types
  module CommitSignatureInterface
    include Types::BaseInterface

    graphql_name 'CommitSignature'

    description 'Represents signing information for a commit'

    field :verification_status, CommitSignatures::VerificationStatusEnum,
      null: true,
      description: 'Indicates verification status of the associated key or certificate.'

    field :commit_sha, GraphQL::Types::String,
      null: true,
      description: 'SHA of the associated commit.'

    field :project, Types::ProjectType,
      null: true,
      description: 'Project of the associated commit.'

    orphan_types Types::CommitSignatures::GpgSignatureType,
      Types::CommitSignatures::X509SignatureType,
      Types::CommitSignatures::SshSignatureType

    def self.resolve_type(object, context)
      case object
      when ::CommitSignatures::GpgSignature
        Types::CommitSignatures::GpgSignatureType
      when ::CommitSignatures::X509CommitSignature
        Types::CommitSignatures::X509SignatureType
      when ::CommitSignatures::SshSignature
        Types::CommitSignatures::SshSignatureType
      else
        raise 'Unsupported commit signature type'
      end
    end
  end
end
