# frozen_string_literal: true

class ApplicationSettingPolicy < BasePolicy # rubocop:disable Gitlab/NamespacedClass
  condition(:runner_registration_token_enabled) { Gitlab::CurrentSettings.allow_runner_registration_token }

  rule { admin }.policy do
    enable :read_application_setting

    enable :read_runners_registration_token
    enable :update_runners_registration_token
  end

  rule { ~runner_registration_token_enabled }.policy do
    prevent :read_runners_registration_token
    prevent :update_runners_registration_token
  end
end
