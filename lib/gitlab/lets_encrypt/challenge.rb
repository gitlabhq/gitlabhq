# frozen_string_literal: true

module Gitlab
  module LetsEncrypt
    class Challenge
      def initialize(acme_challenge)
        @acme_challenge = acme_challenge
      end

      delegate :token, :file_content, :status, :request_validation, :error, to: :acme_challenge

      private

      attr_reader :acme_challenge
    end
  end
end
