# frozen_string_literal: true

module Gitlab
  module LetsEncrypt
    def self.enabled?
      Gitlab::CurrentSettings.lets_encrypt_terms_of_service_accepted
    end

    def self.terms_of_service_url
      ::Gitlab::LetsEncrypt::Client.new.terms_of_service_url
    end
  end
end
