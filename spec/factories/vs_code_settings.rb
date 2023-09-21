# frozen_string_literal: true

FactoryBot.define do
  factory :vscode_setting, class: 'VsCode::VsCodeSetting' do
    user

    setting_type { 'settings' }
    content { '{}' }
  end
end
