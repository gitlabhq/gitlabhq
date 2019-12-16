# frozen_string_literal: true

class UpdateMinimumPasswordLength < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def up
    value_to_be_updated_to = [
      Devise.password_length.min,
      ApplicationSetting::DEFAULT_MINIMUM_PASSWORD_LENGTH
    ].max

    execute "UPDATE application_settings SET minimum_password_length = #{value_to_be_updated_to}"

    ApplicationSetting.expire
  end

  def down
    value_to_be_updated_to = ApplicationSetting::DEFAULT_MINIMUM_PASSWORD_LENGTH

    execute "UPDATE application_settings SET minimum_password_length = #{value_to_be_updated_to}"

    ApplicationSetting.expire
  end
end
