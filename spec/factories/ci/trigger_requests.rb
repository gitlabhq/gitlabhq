FactoryGirl.define do
  factory :ci_trigger_request, class: Ci::TriggerRequest do
    trigger factory: :ci_trigger

    # We switched to Ci::PipelineVariable from Ci::TriggerRequest.variables.
    # Ci::TriggerRequest doesn't save variables anymore, whereas old trigger requests still persist variables.
    factory :ci_trigger_request_with_variables do
      after(:create) do |trigger_request, evaluator|
        trigger_request.update_attribute(:variables, { TRIGGER_KEY_1: 'TRIGGER_VALUE_1', TRIGGER_KEY_2: 'TRIGGER_VALUE_2' } )
      end
    end
  end
end
