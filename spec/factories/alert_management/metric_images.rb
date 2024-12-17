# frozen_string_literal: true

FactoryBot.define do
  factory :alert_metric_image, class: 'AlertManagement::MetricImage' do
    association :alert, factory: :alert_management_alert
    url { generate(:url) }
    project_id { alert&.project_id }

    trait :local do
      file_store { ObjectStorage::Store::LOCAL }
    end

    after(:build) do |image|
      image.file = fixture_file_upload('spec/fixtures/rails_sample.jpg', 'image/jpg')
    end
  end
end
