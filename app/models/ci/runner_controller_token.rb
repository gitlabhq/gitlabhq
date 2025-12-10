# frozen_string_literal: true

module Ci
  class RunnerControllerToken < Ci::ApplicationRecord
    include TokenAuthenticatable

    TOKEN_PREFIX = "glrct-"

    add_authentication_token_field :token,
      digest: true,
      format_with_prefix: :token_prefix

    belongs_to :runner_controller,
      class_name: 'Ci::RunnerController',
      inverse_of: :tokens

    validates :description, length: { maximum: 1024 }

    before_create :ensure_token

    private

    def self.token_prefix
      ::Authn::TokenField::PrefixHelper.prepend_instance_prefix(TOKEN_PREFIX)
    end

    def token_prefix
      self.class.token_prefix
    end
  end
end
