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
      after(:build) do |pipeline|
        allow(pipeline).to receive(:ci_yaml_file) do
          File.read(Rails.root.join('spec/support/gitlab_stubs/gitlab_ci.yml'))
        end
      end
    end

    factory(:ci_pipeline_with_yaml) do
      transient { yaml nil }

      after(:build) do |pipeline, evaluator|
        raise ArgumentError unless evaluator.yaml

        allow(pipeline).to receive(:ci_yaml_file)
          .and_return(YAML.dump(evaluator.yaml))
      end
    end
  end
end
