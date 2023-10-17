# frozen_string_literal: true

FactoryBot.define do
  factory :vscode_setting, class: 'VsCode::Settings::VsCodeSetting' do
    user

    setting_type { 'settings' }
    content { '{}' }
    uuid { SecureRandom.uuid }
    version { 1 }
  end
end
