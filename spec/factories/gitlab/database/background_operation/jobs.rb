# frozen_string_literal: true

FactoryBot.define do
  factory :background_operation_job, class: 'Gitlab::Database::BackgroundOperation::Job' do
    association :worker, factory: :background_operation_worker

    organization_id { create(:common_organization).id }
    batch_size { 100 }
    sub_batch_size { 10 }
    min_cursor { [1] }
    max_cursor { [1000] }
    worker_partition { 1 }

    trait :pending do
      status { 0 }
    end

    trait :running do
      status { 1 }
      started_at { Time.current }
    end

    trait :failed do
      status { 2 }
      attempts { 1 }
    end

    trait :succeeded do
      status { 3 }
      started_at { 1.hour.ago }
      finished_at { Time.current }
    end
  end
end
