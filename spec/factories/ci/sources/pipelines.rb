FactoryGirl.define do
  factory :ci_sources_pipeline, class: Ci::Sources::Pipeline do
    after(:build) do |source|
      source.project ||= source.pipeline.project
      source.source_pipeline ||= source.source_job.pipeline
      source.source_project ||= source.source_pipeline.project
    end
    
    trait :create_source do
      source_job factory: :ci_build
    end
    
    trait :create_target do
      pipeline factory: :ci_empty_pipeline
    end
  end
end
