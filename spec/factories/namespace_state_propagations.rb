# frozen_string_literal: true

FactoryBot.define do
  factory :namespace_state_propagation, class: 'Namespaces::StatePropagation' do
    namespace { association :namespace }
    source_state { :ancestor_inherited }
    target_state { :archived }
    status { :pending }

    trait :pending do
      status { :pending }
    end

    trait :processing do
      status { :processing }
      started_at { Time.current }
    end

    trait :archived_to_ancestor_inherited do
      source_state { :archived }
      target_state { :ancestor_inherited }
    end

    trait :ancestor_inherited_to_archived do
      source_state { :ancestor_inherited }
      target_state { :archived }
    end
  end
end
