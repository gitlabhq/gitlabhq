FactoryGirl.define do
  factory :system_hook do
    url { generate(:url) }
    push_events false
    repository_update_events true
  end
end
