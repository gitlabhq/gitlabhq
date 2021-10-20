# frozen_string_literal: true

FactoryBot.define do
  factory :dependency_proxy_group_setting, class: 'DependencyProxy::GroupSetting' do
    group

    enabled { true }
  end
end
