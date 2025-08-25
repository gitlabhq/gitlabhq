# frozen_string_literal: true

FactoryBot.define do
  factory :work_item_description, class: 'WorkItems::Description' do
    transient do
      work_item { nil }
    end

    description { 'This is a sample work item description' }
    description_html { '<p>This is a sample work item description</p>' }
    lock_version { 0 }
    cached_markdown_version { 1 }

    trait :with_last_editing_user do
      association :last_editing_user, factory: :user
    end

    trait :group_level do
      association :work_item, factory: [:work_item, :group_level]
    end

    trait :empty_description do
      description { nil }
      description_html { nil }
    end

    trait :long_description do
      description { 'A' * 1000 }
      description_html { "<p>#{'A' * 1000}</p>" }
    end

    after(:build) do |description, evaluator|
      description.work_item = evaluator.work_item if evaluator.work_item

      unless description.work_item
        description.work_item = create(:work_item) # rubocop:disable RSpec/FactoryBot/StrategyInCallback-- this is needed for the association

        description.namespace = description.work_item.namespace
        description.root_namespace = description.namespace.root_ancestor
      end
    end
  end
end
