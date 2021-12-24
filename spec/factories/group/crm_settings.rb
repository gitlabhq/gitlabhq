# frozen_string_literal: true

FactoryBot.define do
  factory :crm_settings, class: 'Group::CrmSettings' do
    group
  end
end
