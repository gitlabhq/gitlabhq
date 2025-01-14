# frozen_string_literal: true

module TokenAuthenticatable
  extend ActiveSupport::Concern

  class_methods do
    def encrypted_token_authenticatable_fields
      @encrypted_token_authenticatable_fields ||= []
    end

    # Stores fields that already have been configured via add_authentication_token_field
    def token_authenticatable_fields
      @token_authenticatable_fields ||= []
    end

    # Returns all sensitive fields related to the add_authentication_token_field
    # e.g. token, token_encrypted, token_digest
    def token_authenticatable_sensitive_fields
      @token_authenticatable_sensitive_fields ||= []
    end

    private

    def add_authentication_token_field(token_field, options = {})
      if token_authenticatable_fields.include?(token_field)
        raise ArgumentError, "#{token_field} already configured via add_authentication_token_field"
      end

      token_authenticatable_fields.push(token_field)
      encrypted_token_authenticatable_fields.push(token_field) if options[:encrypted]

      attr_accessor :cleartext_tokens

      strategy = Authn::TokenField::Base.fabricate(self, token_field, options)

      token_authenticatable_sensitive_fields.concat(strategy.sensitive_fields.map(&:to_sym))

      if options.fetch(:unique, true)
        define_singleton_method("find_by_#{token_field}") do |token|
          strategy.find_token_authenticatable(token)
        end
      end

      mod = token_authenticatable_module

      mod.define_method(token_field) do
        strategy.get_token(self)
      end

      mod.define_method("set_#{token_field}") do |token|
        strategy.set_token(self, token)
      end

      mod.define_method("ensure_#{token_field}") do
        strategy.ensure_token(self)
      end

      # Returns a token, but only saves when the database is in read & write mode
      mod.define_method("ensure_#{token_field}!") do
        strategy.ensure_token!(self)
      end

      # Resets the token, but only saves when the database is in read & write mode
      mod.define_method("reset_#{token_field}!") do
        strategy.reset_token!(self)
      end

      mod.define_method("#{token_field}_matches?") do |other_token|
        token = read_attribute(token_field)
        token.present? && ActiveSupport::SecurityUtils.secure_compare(other_token, token)
      end

      mod.define_method("#{token_field}_expires_at") do
        strategy.expires_at(self)
      end

      mod.define_method("#{token_field}_expired?") do
        strategy.expired?(self)
      end

      mod.define_method("#{token_field}_with_expiration") do
        strategy.token_with_expiration(self)
      end
    end

    def token_authenticatable_module
      @token_authenticatable_module ||=
        const_set(:TokenAuthenticatable, Module.new).tap { |mod| include mod }
    end
  end
end
