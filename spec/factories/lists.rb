FactoryGirl.define do
  factory :list do
    board
    label
    sequence(:position)
  end

  factory :backlog_list, parent: :list do
    list_type :backlog
  end

  factory :label_list, parent: :list do
    list_type :label
  end

  factory :done_list, parent: :list do
    list_type :done
  end
end
