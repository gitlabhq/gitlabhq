# frozen_string_literal: true

FactoryBot.define do
  factory :related_link_restriction, class: 'WorkItems::RelatedLinkRestriction' do
    source_type { association :work_item_type }
    target_type { association :work_item_type }
    link_type { 0 }

    initialize_with do
      WorkItems::RelatedLinkRestriction
        .find_or_initialize_by(source_type: source_type, target_type: target_type, link_type: link_type)
    end
  end
end
