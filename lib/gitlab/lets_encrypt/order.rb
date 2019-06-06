# frozen_string_literal: true

module Gitlab
  module LetsEncrypt
    class Order
      def initialize(acme_order)
        @acme_order = acme_order
      end

      def new_challenge
        authorization = @acme_order.authorizations.first
        challenge = authorization.http
        ::Gitlab::LetsEncrypt::Challenge.new(challenge)
      end

      def request_certificate(domain:, private_key:)
        csr = ::Acme::Client::CertificateRequest.new(
          private_key: OpenSSL::PKey.read(private_key),
          subject: { common_name: domain }
        )

        acme_order.finalize(csr: csr)
      end

      delegate :url, :status, :expires, :certificate, to: :acme_order

      private

      attr_reader :acme_order
    end
  end
end
