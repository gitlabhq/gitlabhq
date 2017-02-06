FactoryGirl.define do
  factory :event do
    project factory: :empty_project
    author factory: :user

    trait(:created)   { action Event::CREATED }
    trait(:updated)   { action Event::UPDATED }
    trait(:closed)    { action Event::CLOSED }
    trait(:reopened)  { action Event::REOPENED }
    trait(:pushed)    { action Event::PUSHED }
    trait(:commented) { action Event::COMMENTED }
    trait(:merged)    { action Event::MERGED }
    trait(:joined)    { action Event::JOINED }
    trait(:left)      { action Event::LEFT }
    trait(:destroyed) { action Event::DESTROYED }
    trait(:expired)   { action Event::EXPIRED }

    factory :closed_issue_event do
      action { Event::CLOSED }
      target factory: :closed_issue
    end
  end
end
