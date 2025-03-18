# frozen_string_literal: true

FactoryBot.define do
  factory :dependency_proxy_group_setting, class: 'DependencyProxy::GroupSetting' do
    group

    enabled { true }
    identity { 'username' }
    secret { 'secret' }
  end
end
