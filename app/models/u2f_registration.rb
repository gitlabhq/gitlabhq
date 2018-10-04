# frozen_string_literal: true

# Registration information for U2F (universal 2nd factor) devices, like Yubikeys

class U2fRegistration < ActiveRecord::Base
  belongs_to :user

  def self.register(user, app_id, params, challenges)
    u2f = U2F::U2F.new(app_id)
    registration = self.new

    begin
      response = U2F::RegisterResponse.load_from_json(params[:device_response])
      registration_data = u2f.register!(challenges, response)
      registration.update(certificate: registration_data.certificate,
                          key_handle: registration_data.key_handle,
                          public_key: registration_data.public_key,
                          counter: registration_data.counter,
                          user: user,
                          name: params[:name])
    rescue JSON::ParserError, NoMethodError, ArgumentError
      registration.errors.add(:base, 'Your U2F device did not send a valid JSON response.')
    rescue U2F::Error => e
      registration.errors.add(:base, e.message)
    end

    registration
  end

  def self.authenticate(user, app_id, json_response, challenges)
    response = U2F::SignResponse.load_from_json(json_response)
    registration = user.u2f_registrations.find_by_key_handle(response.key_handle)
    u2f = U2F::U2F.new(app_id)

    if registration
      u2f.authenticate!(challenges, response, Base64.decode64(registration.public_key), registration.counter)
      registration.update(counter: response.counter)
      true
    end
  rescue JSON::ParserError, NoMethodError, ArgumentError, U2F::Error
    false
  end
end
