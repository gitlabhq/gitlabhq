FactoryGirl.define do
  factory :event do
    project factory: :empty_project
    author factory: :user

    factory :closed_issue_event do
      action { Event::CLOSED }
      target factory: :closed_issue
    end
  end
end
