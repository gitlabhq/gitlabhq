# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :ci_trigger_without_token, class: Ci::Trigger do
    factory :trigger do
      token 'token'
    end
  end
end
