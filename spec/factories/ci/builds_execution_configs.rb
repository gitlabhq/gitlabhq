# frozen_string_literal: true

FactoryBot.define do
  factory :ci_builds_execution_configs, class: 'Ci::BuildExecutionConfig' do
    pipeline { association(:ci_pipeline) }

    project_id { pipeline.project_id }
    partition_id { pipeline.partition_id }
    run_steps do
      [
        {
          'name' => 'step1',
          'step' => 'echo',
          'inputs' => { 'message' => 'Hello, World!' }
        }
      ]
    end

    trait :with_script do
      run_steps do
        [
          {
            'name' => 'script1',
            'script' => 'echo "Hello, World!"'
          }
        ]
      end
    end

    trait :with_step_and_script do
      run_steps do
        [
          {
            'name' => 'step1',
            'step' => 'echo',
            'inputs' => { 'message' => 'Hello, World!' }
          },
          {
            'name' => 'script1',
            'script' => 'ls -l'
          }
        ]
      end
    end
  end
end
