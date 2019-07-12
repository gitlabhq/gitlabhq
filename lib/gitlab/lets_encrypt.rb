# frozen_string_literal: true

module Gitlab
  module LetsEncrypt
    def self.enabled?
      Gitlab::CurrentSettings.lets_encrypt_terms_of_service_accepted
    end
  end
end
