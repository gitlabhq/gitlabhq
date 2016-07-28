FactoryGirl.define do
  factory :list do
    board
    label
  end

  factory :backlog_list, parent: :list do
    list_type :backlog
    label nil
    position nil
  end

  factory :label_list, parent: :list do
    list_type :label
    sequence(:position)
  end

  factory :done_list, parent: :list do
    list_type :done
    label nil
    position nil
  end
end
