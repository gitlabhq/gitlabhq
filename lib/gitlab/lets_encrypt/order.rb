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

      delegate :url, :status, to: :acme_order

      private

      attr_reader :acme_order
    end
  end
end
