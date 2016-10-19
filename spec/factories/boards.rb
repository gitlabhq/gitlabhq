FactoryGirl.define do
  factory :board do
    sequence(:name) { |n| "board#{n}" }
    project factory: :empty_project

    after(:create) do |board|
      board.lists.create(list_type: :backlog)
      board.lists.create(list_type: :done)
    end
  end
end
