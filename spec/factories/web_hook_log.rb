# frozen_string_literal: true

FactoryBot.define do
  factory :web_hook_log do
    web_hook factory: :project_hook
    trigger { 'push_hooks' }
    url { generate(:url) }
    request_headers do
      {}
    end
    request_data do
      {}
    end
    response_headers do
      {}
    end
    response_body { '' }
    response_status { '200' }
    execution_duration { 2.0 }
    internal_error_message { nil }
  end
end
