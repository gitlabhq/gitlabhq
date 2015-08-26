# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :trigger_without_token, class: Trigger do
    factory :trigger do
      token 'token'
    end
  end
end
