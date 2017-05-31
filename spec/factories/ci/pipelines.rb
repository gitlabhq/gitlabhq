FactoryGirl.define do
  factory :ci_empty_pipeline, class: Ci::Pipeline do
    ref 'master'
    sha '97de212e80737a608d939f648d959671fb0a0142'
    status 'pending'

    project factory: :empty_project

    factory :ci_pipeline_without_jobs do
      after(:build) do |pipeline|
        allow(pipeline).to receive(:ci_yaml_file) { YAML.dump({}) }
      end
    end

    factory :ci_pipeline_with_one_job do
      after(:build) do |pipeline|
        allow(pipeline).to receive(:ci_yaml_file) do
          YAML.dump({ rspec: { script: "ls" } })
        end
      end
    end

    # Persist merge request head_pipeline_id
    # on pipeline factories to avoid circular references
    transient { head_pipeline_of nil }

    after(:create) do |pipeline, evaluator|
      merge_request = evaluator.head_pipeline_of
      merge_request&.update(head_pipeline: pipeline)
    end

    factory :ci_pipeline do
      transient { config nil }

      after(:build) do |pipeline, evaluator|
        allow(pipeline).to receive(:ci_yaml_file) do
          if evaluator.config
            YAML.dump(evaluator.config)
          else
            File.read(Rails.root.join('spec/support/gitlab_stubs/gitlab_ci.yml'))
          end
        end

        # Populates pipeline with errors
        #
        pipeline.config_processor if evaluator.config
      end

      trait :invalid do
        config(rspec: nil)
      end

      trait :blocked do
        status :manual
      end

      trait :success do
        status :success
      end

      trait :failed do
        status :failed
      end
    end
  end
end
