FactoryBot.define do
  factory :board_label do
    association :board
    association :label
  end
end
