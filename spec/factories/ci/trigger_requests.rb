FactoryGirl.define do
  factory :ci_trigger_request, class: Ci::TriggerRequest do
    factory :ci_trigger_request_with_variables do
      trigger factory: :ci_trigger

      variables do
        {
          TRIGGER_KEY: 'TRIGGER_VALUE'
        }
      end
    end
  end
end
