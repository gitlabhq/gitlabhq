FactoryBot.define do
  factory :epic_issue do
    epic
    issue
    relative_position { Gitlab::Database::MAX_INT_VALUE / 2 }
  end
end
