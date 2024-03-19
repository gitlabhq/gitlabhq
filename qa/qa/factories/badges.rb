# frozen_string_literal: true

module QA
  FactoryBot.define do
    factory :group_badge, class: 'QA::Resource::GroupBadge' do
      link_url { 'http://example.com/badge' }
      image_url { 'http://shields.io/badge' }
    end
  end
end
