FactoryGirl.define do
  factory :board do
<<<<<<< HEAD
    sequence(:name) { |n| "board#{n}" }
=======
>>>>>>> ce/master
    project

    after(:create) do |board|
      board.lists.create(list_type: :closed)
    end
  end
end
