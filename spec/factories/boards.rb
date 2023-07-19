# frozen_string_literal: true

FactoryBot.define do
  factory :board do
    transient do
      project { nil }
      group { nil }
      project_id { nil }
      group_id { nil }
      resource_parent { nil }
    end

    after(:build, :stub) do |board, evaluator|
      if evaluator.group
        board.group = evaluator.group
      elsif evaluator.group_id
        board.group_id = evaluator.group_id
      elsif evaluator.project
        board.project = evaluator.project
      elsif evaluator.project_id
        board.project_id = evaluator.project_id
      elsif evaluator.resource_parent
        id = evaluator.resource_parent.id
        evaluator.resource_parent.is_a?(Group) ? board.group_id = id : evaluator.project_id = id
      else
        board.project = create(:project, :empty_repo)
      end
    end

    after(:create) do |board|
      board.lists.create!(list_type: :backlog)
      board.lists.create!(list_type: :closed)
    end
  end

  factory :group_board, parent: :board do
    group
  end
end
