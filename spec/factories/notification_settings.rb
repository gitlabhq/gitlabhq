FactoryBot.define do
  factory :notification_setting do
    source factory: :project
    user
    level 3
  end
end
