# frozen_string_literal: true

FactoryBot.define do
  factory :saved_view, class: 'WorkItems::SavedViews::SavedView' do
    name { generate(:title) }
    description { FFaker::Lorem.sentence }
    namespace { association(:group) }
    author { association(:user) }
    private { false }
    version { 1 }
  end
end
