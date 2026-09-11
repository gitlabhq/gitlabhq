# frozen_string_literal: true

module Gitlab
  module SshCertificates
    # Shared by the group and instance find services and by the
    # /internal/authorized_certs endpoint that maps them to HTTP statuses.
    module Reason
      CERTIFICATE_NOT_FOUND = :certificate_not_found
      USER_NOT_FOUND = :user_not_found
      FEATURE_NOT_AVAILABLE = :feature_not_available
      NOT_ENTERPRISE_USER = :not_enterprise_user
    end
  end
end
