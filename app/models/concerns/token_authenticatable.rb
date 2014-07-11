module TokenAuthenticatable
  extend ActiveSupport::Concern

  module ClassMethods
    def find_by_authentication_token(authentication_token = nil)
      if authentication_token
        where(authentication_token: authentication_token).first
      end
    end
  end

  def ensure_authentication_token
    if authentication_token.blank?
      self.authentication_token = generate_authentication_token
    end
  end

  def reset_authentication_token!
    self.authentication_token = generate_authentication_token
    save
  end

  private

  def generate_authentication_token
    loop do
      token = Devise.friendly_token
      break token unless self.class.unscoped.where(authentication_token: token).first
    end
  end
end
