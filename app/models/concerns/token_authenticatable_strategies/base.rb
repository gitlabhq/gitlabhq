# frozen_string_literal: true

module TokenAuthenticatableStrategies
  class Base
    RANDOM_BYTES_LENGTH = 16

    attr_reader :klass, :token_field, :expires_at_field, :options

    def self.random_bytes
      SecureRandom.random_bytes(RANDOM_BYTES_LENGTH)
    end

    def initialize(klass, token_field, options)
      @klass = klass
      @token_field = token_field
      @expires_at_field = "#{token_field}_expires_at"
      @options = options
    end

    def find_token_authenticatable(token_owner_record, unscoped = false)
      raise NotImplementedError
    end

    def get_token(token_owner_record)
      raise NotImplementedError
    end

    def set_token(token_owner_record, token)
      raise NotImplementedError
    end

    def token_fields
      result = [token_field]

      result << @expires_at_field if expirable?

      result
    end

    # The expires_at field is not considered sensitive
    def sensitive_fields
      token_fields - [@expires_at_field]
    end

    def ensure_token(token_owner_record)
      write_new_token(token_owner_record) unless token_set?(token_owner_record)
      get_token(token_owner_record)
    end

    # Returns a token, but only saves when the database is in read & write mode
    def ensure_token!(token_owner_record)
      reset_token!(token_owner_record) unless token_set?(token_owner_record)
      get_token(token_owner_record)
    end

    # Resets the token, but only saves when the database is in read & write mode
    def reset_token!(token_owner_record)
      write_new_token(token_owner_record)
      token_owner_record.save! if Gitlab::Database.read_write?
    end

    def expires_at(token_owner_record)
      token_owner_record.read_attribute(@expires_at_field)
    end

    def expired?(token_owner_record)
      return false unless expirable? && token_expiration_enforced?

      exp = expires_at(token_owner_record)
      !!exp && exp.past?
    end

    def expirable?
      !!@options[:expires_at]
    end

    def token_with_expiration(token_owner_record)
      API::Support::TokenWithExpiration.new(self, token_owner_record)
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

    private

    def prefix_for(token_owner_record)
      case prefix_option = options[:format_with_prefix]
      when nil
        nil
      when Symbol
        token_owner_record.send(prefix_option) # rubocop:disable GitlabSecurity/PublicSend
      else
        raise NotImplementedError
      end
    end

    # If a `format_with_prefix` option is provided, it applies and returns the formatted token.
    # Otherwise, default implementation returns the token as-is
    def format_token(token_owner_record, token)
      prefix = prefix_for(token_owner_record)

      prefix ? "#{prefix}#{token}" : token
    end

    def write_new_token(token_owner_record)
      new_token = generate_available_token(token_owner_record)
      formatted_token = format_token(token_owner_record, new_token)
      set_token(token_owner_record, formatted_token)

      if expirable?
        token_owner_record[@expires_at_field] = @options[:expires_at].to_proc.call(token_owner_record)
      end
    end

    def unique
      @options.fetch(:unique, true)
    end

    def generate_available_token(token_owner_record)
      loop do
        token = generate_token(token_owner_record)
        break token unless unique && find_token_authenticatable(token, true)
      end
    end

    def generate_token(token_owner_record)
      if @options[:token_generator]
        @options[:token_generator].call
      # TODO: Make all tokens routable by default: https://gitlab.com/gitlab-org/gitlab/-/issues/500016
      elsif generate_routable_token?(token_owner_record)
        generate_routable_payload(@options[:routable_token], token_owner_record)
      else
        Devise.friendly_token
      end
    end

    def generate_routable_token?(token_owner_record)
      @options[:routable_token] && token_owner_record.respond_to?(:user) && Feature.enabled?(:routable_token, token_owner_record.user)
    end

    def default_routing_payload_hash
      {
        c: Settings.cell[:id]&.to_s(36),
        r: self.class.random_bytes
      }
    end

    def generate_routable_payload(routable_parts, token_owner_record)
      payload_hash = default_routing_payload_hash.merge(
        routable_parts.transform_values { |generator| generator.call(token_owner_record) }
      ).compact_blank

      Base64.urlsafe_encode64(payload_hash.sort.map { |k, v| "#{k}:#{v}" }.join("\n"), padding: false)
    end

    def relation(unscoped)
      unscoped ? @klass.unscoped : @klass.where(not_expired)
    end

    def token_set?(token_owner_record)
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
