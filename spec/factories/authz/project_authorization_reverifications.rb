# frozen_string_literal: true

FactoryBot.define do
  factory :project_authorization_reverification, class: 'Authz::ProjectAuthorizationReverification' do
    user
    enqueued_at { Time.current }

    trait :processing do
      status { :processing }
      refresh_started_at { Time.current }
    end

    trait :requeued do
      status { :requeued }
      refresh_started_at { Time.current }
    end

    trait :abandoned do
      status { :processing }
      refresh_started_at { Authz::ProjectAuthorizationReverification::PROCESSING_TIMEOUT.ago - 1.minute }
    end

    trait :to_be_processed do
      enqueued_at { Authz::ProjectAuthorizationReverification::MIN_AGE.ago - 1.minute }
    end
  end
end
