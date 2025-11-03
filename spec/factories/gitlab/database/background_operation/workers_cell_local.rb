# frozen_string_literal: true

FactoryBot.define do
  factory :background_operation_worker_cell_local, class: 'Gitlab::Database::BackgroundOperation::WorkerCellLocal' do
    job_class_name { 'DummyTest' }
    batch_class_name { 'PrimaryKey' }
    table_name { :users }
    column_name { :id }
    gitlab_schema { :gitlab_main_org }
    batch_size { 1000 }
    sub_batch_size { 100 }
    pause_ms { 100 }
    priority { 0 }
    interval { 2.minutes }
    sequence(:job_arguments) { |n| [["column_#{n}"], ["column_#{n}_convert_to_bigint"]] }
    min_cursor { [1] }
    max_cursor { [1000] }

    trait :queued do
      status { 0 }
    end

    trait :active do
      status { 1 }
    end

    trait :paused do
      status { 2 }
      on_hold_until { 2.days.after }
    end

    trait :finished do
      status { 3 }
    end

    trait :failed do
      status { 4 }
    end
  end
end
