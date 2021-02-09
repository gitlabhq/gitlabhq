# frozen_string_literal: true

class ApplicationSettingPolicy < BasePolicy # rubocop:disable Gitlab/NamespacedClass
  rule { admin }.enable :read_application_setting
end
