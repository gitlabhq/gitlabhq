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
        if current_token.blank?
          write_attribute(token_field, generate_token_for(token_field))
        else
          current_token
        end
      end

      define_method("reset_#{token_field}!") do
        write_attribute(token_field, generate_token_for(token_field))
        save!
      end
    end
  end

  private

  def generate_token_for(token_field)
    loop do
      token = Devise.friendly_token
      break token unless self.class.unscoped.find_by(token_field => token)
    end
  end
end
