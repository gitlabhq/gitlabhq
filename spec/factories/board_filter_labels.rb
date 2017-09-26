FactoryGirl.define do
  factory :board_filter_label do
    association :board_filter
    association :label
  end
end
