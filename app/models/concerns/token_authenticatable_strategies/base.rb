# frozen_string_literal: true

module TokenAuthenticatableStrategies
  class Base
    attr_reader :klass, :token_field, :options

    def initialize(klass, token_field, options)
      @klass = klass
      @token_field = token_field
      @expires_at_field = "#{token_field}_expires_at"
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

    def token_fields
      result = [token_field]

      result << @expires_at_field if expirable?

      result
    end

    # If a `format_with_prefix` option is provided, it applies and returns the formatted token.
    # Otherwise, default implementation returns the token as-is
    def format_token(instance, token)
      prefix = prefix_for(instance)
      prefixed_token = prefix ? "#{prefix}#{token}" : token

      instance.send("format_#{@token_field}", prefixed_token) # rubocop:disable GitlabSecurity/PublicSend
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
      instance.save! if Gitlab::Database.read_write?
    end

    def expires_at(instance)
      instance.read_attribute(@expires_at_field)
    end

    def expired?(instance)
      return false unless expirable? && token_expiration_enforced?

      exp = expires_at(instance)
      !!exp && exp.past?
    end

    def expirable?
      !!@options[:expires_at]
    end

    def token_with_expiration(instance)
      API::Support::TokenWithExpiration.new(self, instance)
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

    def prefix_for(instance)
      case prefix_option = options[:format_with_prefix]
      when nil
        nil
      when Symbol
        instance.send(prefix_option) # rubocop:disable GitlabSecurity/PublicSend
      else
        raise NotImplementedError
      end
    end

    def write_new_token(instance)
      new_token = generate_available_token
      formatted_token = format_token(instance, new_token)
      set_token(instance, formatted_token)

      if expirable?
        instance[@expires_at_field] = @options[:expires_at].to_proc.call(instance)
      end
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
      unscoped ? @klass.unscoped : @klass.where(not_expired)
    end

    def token_set?(instance)
      raise NotImplementedError
    end

    def token_expiration_enforced?
      return true unless @options[:expiration_enforced?]

      @options[:expiration_enforced?].to_proc.call(@klass)
    end

    def not_expired
      Arel.sql("#{@expires_at_field} IS NULL OR #{@expires_at_field} >= NOW()") if expirable? && token_expiration_enforced?
    end
  end
end
