# frozen_string_literal: true

module TokenAuthenticatableStrategies
  class Base
    attr_reader :klass, :token_field, :options

    def initialize(klass, token_field, options)
      @klass = klass
      @token_field = token_field
      @options = options
    end

    def find_token_authenticatable(instance, unscoped = false)
      raise NotImplementedError
    end

    def get_token(instance)
      raise NotImplementedError
    end

    def set_token(instance, token)
      raise NotImplementedError
    end

    # Default implementation returns the token as-is
    def format_token(instance, token)
      instance.send("format_#{@token_field}", token) # rubocop:disable GitlabSecurity/PublicSend
    end

    def ensure_token(instance)
      write_new_token(instance) unless token_set?(instance)
      get_token(instance)
    end

    # Returns a token, but only saves when the database is in read & write mode
    def ensure_token!(instance)
      reset_token!(instance) unless token_set?(instance)
      get_token(instance)
    end

    # Resets the token, but only saves when the database is in read & write mode
    def reset_token!(instance)
      write_new_token(instance)
      instance.save! if Gitlab::Database.main.read_write?
    end

    def self.fabricate(model, field, options)
      if options[:digest] && options[:encrypted]
        raise ArgumentError, _('Incompatible options set!')
      end

      if options[:digest]
        TokenAuthenticatableStrategies::Digest.new(model, field, options)
      elsif options[:encrypted]
        TokenAuthenticatableStrategies::Encrypted.new(model, field, options)
      else
        TokenAuthenticatableStrategies::Insecure.new(model, field, options)
      end
    end

    protected

    def write_new_token(instance)
      new_token = generate_available_token
      formatted_token = format_token(instance, new_token)
      set_token(instance, formatted_token)
    end

    def unique
      @options.fetch(:unique, true)
    end

    def generate_available_token
      loop do
        token = generate_token
        break token unless unique && find_token_authenticatable(token, true)
      end
    end

    def generate_token
      @options[:token_generator] ? @options[:token_generator].call : Devise.friendly_token
    end

    def relation(unscoped)
      unscoped ? @klass.unscoped : @klass
    end

    def token_set?(instance)
      raise NotImplementedError
    end
  end
end
