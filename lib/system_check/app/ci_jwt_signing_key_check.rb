# frozen_string_literal: true

module SystemCheck
  module App
    class CiJwtSigningKeyCheck < SystemCheck::BaseCheck
      set_name 'Valid CI JWT signing key?'

      def check?
        key_data = Rails.application.secrets.ci_jwt_signing_key
        return false unless key_data.present?

        OpenSSL::PKey::RSA.new(key_data)

        true
      rescue OpenSSL::PKey::RSAError
        false
      end

      def show_error
        $stdout.puts '  Rails.application.secrets.ci_jwt_signing_key is missing or not a valid RSA key.'.color(:red)
        $stdout.puts '  CI_JOB_JWT will not be generated for CI jobs.'.color(:red)

        for_more_information(
          'doc/ci/variables/predefined_variables.md',
          'doc/ci/examples/authenticating-with-hashicorp-vault/index.md'
        )
      end
    end
  end
end
