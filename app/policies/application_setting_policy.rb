# frozen_string_literal: true

class ApplicationSettingPolicy < BasePolicy # rubocop:disable Gitlab/NamespacedClass
  rule { admin }.policy do
    enable :read_application_setting
    enable :update_runners_registration_token
  end
end
