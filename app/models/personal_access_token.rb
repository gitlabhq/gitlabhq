class PersonalAccessToken < ActiveRecord::Base
  belongs_to :user

  def self.generate(params)
    personal_access_token = self.new(params)
    personal_access_token.token = Devise.friendly_token(50)
    personal_access_token
  end
end
