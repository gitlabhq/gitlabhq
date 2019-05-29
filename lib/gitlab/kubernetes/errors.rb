# frozen_string_literal: true

module Gitlab
  module Kubernetes
    module Errors
      CONNECTION = [
        SocketError,
        OpenSSL::SSL::SSLError,
        Errno::ECONNRESET,
        Errno::ENETUNREACH,
        Errno::ECONNREFUSED,
        Errno::EHOSTUNREACH,
        Net::OpenTimeout,
        Net::ReadTimeout,
        IPAddr::InvalidAddressError
      ].freeze

      AUTHENTICATION = [
        OpenSSL::X509::CertificateError
      ].freeze
    end
  end
end
