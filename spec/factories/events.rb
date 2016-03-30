FactoryGirl.define do
  factory :event do
    factory :closed_issue_event do
      project
      action { Event::CLOSED }
      target factory: :closed_issue
      author factory: :user
    end
  end
end
