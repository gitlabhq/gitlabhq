# frozen_string_literal: true

FactoryBot.define do
  factory :parent_link, class: 'WorkItems::ParentLink' do
    transient do
      work_item { nil }
      work_item_parent { nil }
    end

    trait :with_epic_issue do
      after(:create) do |link, _evaluator|
        issue = Issue.find(link.work_item_id)

        create(:epic_issue,
          epic: link.work_item_parent.synced_epic,
          issue: issue,
          work_item_parent_link: link,
          relative_position: link.relative_position
        )
      end
    end

    after(:build) do |link, evaluator|
      link.work_item = evaluator.work_item if evaluator.work_item
      link.work_item_parent = evaluator.work_item_parent if evaluator.work_item_parent

      unless link.work_item && link.work_item_parent
        project = link.work_item&.project || link.work_item_parent&.project || create(:project)
        link.work_item ||= create(:work_item, :task, project: project)
        link.work_item_parent ||= create(:work_item, project: project)
      end
    end
  end
end
