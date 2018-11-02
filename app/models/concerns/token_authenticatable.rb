# frozen_string_literal: true

module TokenAuthenticatable
  extend ActiveSupport::Concern

  private

  class_methods do
    private # rubocop:disable Lint/UselessAccessModifier

    def add_authentication_token_field(token_field, options = {})
      @token_fields = [] unless @token_fields
      unique = options.fetch(:unique, true)

      if @token_fields.include?(token_field)
        raise ArgumentError.new("#{token_field} already configured via add_authentication_token_field")
      end

      @token_fields << token_field

      attr_accessor :cleartext_tokens

      strategy = if options[:digest]
                   TokenAuthenticatableStrategies::Digest.new(self, token_field, options)
                 else
                   TokenAuthenticatableStrategies::Insecure.new(self, token_field, options)
                 end

      if unique
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
    end
  end
end
