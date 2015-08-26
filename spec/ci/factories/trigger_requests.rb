# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :trigger_request do
    factory :trigger_request_with_variables do
      variables do
        {
          TRIGGER_KEY: 'TRIGGER_VALUE'
        }
      end
    end
  end
end
