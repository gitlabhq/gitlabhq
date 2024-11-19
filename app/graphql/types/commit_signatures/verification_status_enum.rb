# frozen_string_literal: true

module Types
  module CommitSignatures
    class VerificationStatusEnum < BaseEnum
      graphql_name 'VerificationStatus'
      description 'Verification status of a GPG, X.509 or SSH signature for a commit.'

      ::Enums::CommitSignature.verification_statuses.each_key do |status|
        value status.to_s.upcase, value: status.to_s, description: "#{status} verification status."
      end
    end
  end
end
