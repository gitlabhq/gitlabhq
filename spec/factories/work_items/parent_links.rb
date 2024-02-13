# frozen_string_literal: true

FactoryBot.define do
  factory :parent_link, class: 'WorkItems::ParentLink' do
    transient do
      work_item { nil }
      work_item_parent { nil }
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
