FactoryGirl.define do
  factory :board_filter_label do
    association :board
    association :label
  end
end
