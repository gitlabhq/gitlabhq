FactoryGirl.define do
  factory :related_issue do
    issue
    related_issue factory: :issue
  end
end
