# frozen_string_literal: true

# rubocop:disable Graphql/AuthorizeTypes

module Types
  module CommitSignatures
    class VerificationStatusEnum < BaseEnum
      graphql_name 'VerificationStatus'
      description 'Verification status of a GPG or X.509 signature for a commit.'

      ::CommitSignatures::GpgSignature.verification_statuses.each do |status, _|
        value status.upcase, value: status, description: "#{status} verification status."
      end
    end
  end
end

# rubocop:enable Graphql/AuthorizeTypes
