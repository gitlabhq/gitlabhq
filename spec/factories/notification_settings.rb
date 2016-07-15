FactoryGirl.define do
  factory :notification_setting do
    source factory: :empty_project
    user
    level 3
    events []
  end
end
