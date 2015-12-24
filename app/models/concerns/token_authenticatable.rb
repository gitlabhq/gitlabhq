module TokenAuthenticatable
  extend ActiveSupport::Concern

  class_methods do
    def authentication_token_fields
      @token_fields || []
    end

    private

    def add_authentication_token_field(token_field)
      @token_fields = [] unless @token_fields
      @token_fields << token_field

      define_singleton_method("find_by_#{token_field}") do |token|
        find_by(token_field => token) if token
      end

      define_method("ensure_#{token_field}") do
        current_token = read_attribute(token_field)
        current_token.blank? ? write_new_token(token_field) : current_token
      end

      define_method("ensure_#{token_field}!") do
        send("reset_#{token_field}!") if read_attribute(token_field).blank?
        read_attribute(token_field)
      end

      define_method("reset_#{token_field}!") do
        write_new_token(token_field)
        save!
      end
    end
  end

  private

  def write_new_token(token_field)
    new_token = generate_token(token_field)
    write_attribute(token_field, new_token)
  end

  def generate_token(token_field)
    loop do
      token = Devise.friendly_token
      break token unless self.class.unscoped.find_by(token_field => token)
    end
  end
end
