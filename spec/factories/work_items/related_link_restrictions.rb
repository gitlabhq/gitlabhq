# frozen_string_literal: true

FactoryBot.define do
  factory :related_link_restriction, class: 'WorkItems::RelatedLinkRestriction' do
    source_type { association :work_item_type, :default }
    target_type { association :work_item_type, :default }
    link_type { 0 }
  end
end
