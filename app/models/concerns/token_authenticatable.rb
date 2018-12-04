# frozen_string_literal: true

module TokenAuthenticatable
  extend ActiveSupport::Concern

  private

  class_methods do
    private # rubocop:disable Lint/UselessAccessModifier

    def add_authentication_token_field(token_field, options = {})
      if token_authenticatable_fields.include?(token_field)
        raise ArgumentError.new("#{token_field} already configured via add_authentication_token_field")
      end

      token_authenticatable_fields.push(token_field)

      attr_accessor :cleartext_tokens

      strategy = TokenAuthenticatableStrategies::Base
        .fabricate(self, token_field, options)

      if options.fetch(:unique, true)
        define_singleton_method("find_by_#{token_field}") do |token|
          strategy.find_token_authenticatable(token)
        end
      end

      define_method(token_field) do
        strategy.get_token(self)
      end

      define_method("set_#{token_field}") do |token|
        strategy.set_token(self, token)
      end

      define_method("ensure_#{token_field}") do
        strategy.ensure_token(self)
      end

      # Returns a token, but only saves when the database is in read & write mode
      define_method("ensure_#{token_field}!") do
        strategy.ensure_token!(self)
      end

      # Resets the token, but only saves when the database is in read & write mode
      define_method("reset_#{token_field}!") do
        strategy.reset_token!(self)
      end

      define_method("#{token_field}_matches?") do |other_token|
        token = read_attribute(token_field)
        token.present? && ActiveSupport::SecurityUtils.variable_size_secure_compare(other_token, token)
      end
    end

    def token_authenticatable_fields
      @token_authenticatable_fields ||= []
    end
  end
end
