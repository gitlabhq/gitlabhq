# frozen_string_literal: true

FactoryBot.define do
  factory :ci_job_definition, class: 'Ci::JobDefinition' do
    project factory: :project

    checksum { Digest::SHA256.hexdigest(rand.to_s) }
    interruptible { false }

    trait :with_step_and_script do
      config do
        {
          run_steps:
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
        }
      end
    end
  end
end
