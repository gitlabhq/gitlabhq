FactoryGirl.define do
  factory :board do
    project factory: :empty_project

    after(:create) do |board|
      board.lists.create(list_type: :closed)
    end
  end
end
