FactoryGirl.define do
  factory :ci_trigger_without_token, class: Ci::Trigger do
    factory :ci_trigger do
      sequence(:token) { |n| "token#{n}" }

      factory :ci_trigger_for_trigger_schedule do
        token { SecureRandom.hex(15) }
        owner factory: :user
        project factory: :project
        ref 'master'
      end
    end
  end
end
