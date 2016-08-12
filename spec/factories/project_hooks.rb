FactoryGirl.define do
  factory :project_hook do
    url { FFaker::Internet.uri('http') }

    trait :token do
      token { SecureRandom.hex(10) }
    end

    trait :all_events_enabled do
      %w[push_events
         merge_requests_events
         tag_push_events
         issues_events
         note_events
         build_events
         pipeline_events].each do |event|
        send(event, true)
      end
    end
  end
end
