FactoryGirl.define do
  factory :ci_stage, class: Ci::Stage do
    transient do
      name 'test'
      status nil
      warnings nil
      pipeline factory: :ci_empty_pipeline
    end

    initialize_with do
      Ci::Stage.new(pipeline, name: name, status: status, warnings: warnings)
    end
  end
end
