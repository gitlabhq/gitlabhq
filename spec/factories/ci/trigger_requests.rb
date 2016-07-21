FactoryGirl.define do
  factory :ci_trigger_request, class: Ci::TriggerRequest do
    factory :ci_trigger_request_with_variables do
      trigger factory: :ci_trigger

      variables do
        {
          TRIGGER_KEY_1: 'TRIGGER_VALUE_1',
          TRIGGER_KEY_2: 'TRIGGER_VALUE_2'
        }
      end
    end
  end
end
