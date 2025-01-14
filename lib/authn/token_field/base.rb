# frozen_string_literal: true

module Authn
  module TokenField
    class Base
      TRUE_PROC = ->(_) { true }

      attr_reader :klass, :token_field, :expires_at_field, :options

      def self.fabricate(model, field, options)
        raise ArgumentError, _('Incompatible options set!') if options[:digest] && options[:encrypted]

        if options[:digest]
          Authn::TokenField::Digest.new(model, field, options)
        elsif options[:encrypted]
          Authn::TokenField::Encrypted.new(model, field, options)
        else
          Authn::TokenField::Insecure.new(model, field, options)
        end
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

      private

      # If a `format_with_prefix` option is provided, it applies and returns the formatted token.
      # Otherwise, default implementation returns the token as-is
      def prefix_for(token_owner_record)
        case prefix_option = options[:format_with_prefix]
        when nil
          nil
        when Symbol
          token_owner_record.send(prefix_option) # rubocop:disable GitlabSecurity/PublicSend -- We allow specifying a private method for `:format_with_prefix`.
        else
          raise NotImplementedError
        end
      end

      def write_new_token(token_owner_record)
        new_token = generate_available_token(token_owner_record)
        set_token(token_owner_record, new_token)

        return unless expirable?

        token_owner_record[@expires_at_field] = @options[:expires_at].to_proc.call(token_owner_record)
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
        if token_generator_proc
          "#{prefix_for(token_owner_record)}#{token_generator_proc.call}"
        # TODO: Make all tokens routable by default: https://gitlab.com/gitlab-org/gitlab/-/issues/500016
        elsif generate_routable_token?(token_owner_record)
          Authn::TokenField::Generator::RoutableToken.new(
            token_owner_record,
            routing_payload: options.dig(:routable_token, :payload),
            prefix: prefix_for(token_owner_record)
          ).generate_token
        else
          "#{prefix_for(token_owner_record)}#{Devise.friendly_token}"
        end
      end

      def generate_routable_token?(token_owner_record)
        @options.dig(:routable_token, :payload) && routing_condition_proc.call(token_owner_record)
      end

      def token_generator_proc
        @options[:token_generator]
      end

      def routing_condition_proc
        @options.dig(:routable_token, :if) || TRUE_PROC
      end

      def relation(unscoped)
        unscoped ? @klass.unscoped : @klass.where(not_expired) # rubocop:disable CodeReuse/ActiveRecord: -- This is meant to be used in AR models.
      end

      def token_set?(token_owner_record)
        raise NotImplementedError
      end

      def token_expiration_enforced?
        return true unless @options[:expiration_enforced?]

        @options[:expiration_enforced?].to_proc.call(@klass)
      end

      def not_expired
        if expirable? && token_expiration_enforced? # rubocop:disable Style/GuardClause -- We don't want `unless` with multiple conditions, not multiple `if` guard clauses
          Arel.sql("#{@expires_at_field} IS NULL OR #{@expires_at_field} >= NOW()")
        end
      end
    end
  end
end
