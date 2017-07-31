FactoryGirl.define do
  factory :geo_event_log_state, class: Geo::EventLogState do
    skip_create

    sequence(:event_id)
  end
end
