# frozen_string_literal: true

# rubocop:disable Gitlab/BoundedContexts -- Mirrors the top-level InstanceSshCertificate model
module InstanceSshCertificates
  class FindService
    Reason = ::Gitlab::SshCertificates::Reason

    def initialize(ca_fingerprint, user_identifier)
      @ca_fingerprint = ca_fingerprint
      @user_identifier = user_identifier
    end

    def execute
      return error('Certificate Not Found', Reason::CERTIFICATE_NOT_FOUND) unless certificate_registered?

      user = ::User.find_by_login(user_identifier)
      return error('User Not Found', Reason::USER_NOT_FOUND) unless user

      ServiceResponse.success(payload: { user: user })
    end

    private

    attr_reader :ca_fingerprint, :user_identifier

    def certificate_registered?
      ::InstanceSshCertificate.available? &&
        ::InstanceSshCertificate.for_fingerprint(ca_fingerprint).exists?
    end

    def error(message, reason)
      ServiceResponse.error(message: message, reason: reason)
    end
  end
end
# rubocop:enable Gitlab/BoundedContexts
