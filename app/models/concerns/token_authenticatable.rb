# frozen_string_literal: true

module TokenAuthenticatable
  extend ActiveSupport::Concern

  private

  def write_new_token(token_field, unique: true)
    new_token = generate_available_token(token_field, unique: unique)
    write_attribute(token_field, new_token)
  end

  def generate_available_token(token_field, unique:)
    loop do
      token = generate_token(token_field)
      break token unless unique && self.class.unscoped.find_by(token_field => token)
    end
  end

  def generate_token(token_field)
    Devise.friendly_token
  end

  class_methods do
    def authentication_token_fields
      @token_fields || []
    end

    private # rubocop:disable Lint/UselessAccessModifier

    def add_authentication_token_field(token_field, unique: true)
      @token_fields = [] unless @token_fields
      @token_fields << token_field

      if unique
        define_singleton_method("find_by_#{token_field}") do |token|
          find_by(token_field => token) if token
        end
      end

      define_method("ensure_#{token_field}") do
        current_token = read_attribute(token_field)
        current_token.blank? ? write_new_token(token_field, unique: unique) : current_token
      end

      define_method("set_#{token_field}") do |token|
        write_attribute(token_field, token) if token
      end

      # Returns a token, but only saves when the database is in read & write mode
      define_method("ensure_#{token_field}!") do
        send("reset_#{token_field}!") if read_attribute(token_field).blank? # rubocop:disable GitlabSecurity/PublicSend

        read_attribute(token_field)
      end

      # Resets the token, but only saves when the database is in read & write mode
      define_method("reset_#{token_field}!") do
        write_new_token(token_field, unique: unique)
        save! if Gitlab::Database.read_write?
      end
    end
  end
end
