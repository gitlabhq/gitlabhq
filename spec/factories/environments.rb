# frozen_string_literal: true

FactoryBot.define do
  factory :environment, class: 'Environment' do
    sequence(:name) { |n| "environment#{n}" }

    association :project, :repository
    sequence(:external_url) { |n| "https://env#{n}.example.gitlab.com" }

    trait :available do
      state { :available }
    end

    trait :stopped do
      state { :stopped }
    end

    trait :production do
      name { 'production' }
    end

    trait :staging do
      name { 'staging' }
    end

    trait :testing do
      name { 'testing' }
    end

    trait :development do
      name { 'development' }
    end

    trait :with_review_app do |environment|
      sequence(:name) { |n| "review/#{n}" }

      transient do
        ref { 'master' }
      end

      # At this point `review app` is an ephemeral concept related to
      # deployments being deployed for given environment. There is no
      # first-class `review app` available so we need to create set of
      # interconnected objects to simulate a review app.
      #
      after(:create) do |environment, evaluator|
        pipeline = create(:ci_pipeline, project: environment.project)

        deployable = create(:ci_build, name: "#{environment.name}:deploy",
                                       pipeline: pipeline)

        deployment = create(:deployment,
                            :success,
                            environment: environment,
                            project: environment.project,
                            deployable: deployable,
                            ref: evaluator.ref,
                            sha: environment.project.commit(evaluator.ref).id)

        teardown_build = create(:ci_build, :manual,
                                name: "#{environment.name}:teardown",
                                pipeline: pipeline)

        deployment.update_column(:on_stop, teardown_build.name)
        environment.update_attribute(:deployments, [deployment])
      end
    end

    trait :non_playable do
      status { 'created' }
      self.when { 'manual' }
    end

    trait :auto_stoppable do
      auto_stop_at { 1.day.ago }
    end

    trait :will_auto_stop do
      auto_stop_at { 1.day.from_now }
    end
  end
end
