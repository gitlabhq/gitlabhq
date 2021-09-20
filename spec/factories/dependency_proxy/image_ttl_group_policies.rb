# frozen_string_literal: true

FactoryBot.define do
  factory :image_ttl_group_policy, class: 'DependencyProxy::ImageTtlGroupPolicy' do
    group

    enabled { true }
    ttl { 90 }
  end
end
