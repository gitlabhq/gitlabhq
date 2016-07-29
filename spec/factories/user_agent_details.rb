FactoryGirl.define do
  factory :user_agent_detail do
    ip_address '127.0.0.1'
    user_agent 'AppleWebKit/537.36'
    subject_id 1
    subject_type 'Issue'

    trait :on_issue do
      association :subject, factory: :issue
    end
  end
end
