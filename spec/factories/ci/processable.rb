# frozen_string_literal: true

FactoryBot.define do
  factory :ci_processable, class: 'Ci::Processable' do
    name { 'processable' }
    stage { 'test' }
    stage_idx { 0 }
    ref { 'master' }
    tag { false }
    pipeline factory: :ci_pipeline
    project { pipeline.project }
    scheduling_type { 'stage' }

    trait :waiting_for_resource do
      status { 'waiting_for_resource' }
    end

    trait :resource_group do
      waiting_for_resource_at { 5.minutes.ago }

      after(:build) do |processable, evaluator|
        processable.resource_group = create(:ci_resource_group, project: processable.project)
      end
    end
  end
end
