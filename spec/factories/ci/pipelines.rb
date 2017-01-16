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
    end
  end
end
