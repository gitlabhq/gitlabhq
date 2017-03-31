FactoryGirl.define do
  factory :ci_trigger_without_token, class: Ci::Trigger do
    factory :ci_trigger do
      token { SecureRandom.hex(15) }

      factory :ci_trigger_for_trigger_schedule do
        owner factory: :user
        project factory: :project
        ref 'master'
      end
    end
  end
end
