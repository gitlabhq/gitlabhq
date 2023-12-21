# frozen_string_literal: true

FactoryBot.define do
  factory :ci_pipeline_chat_data, class: 'Ci::PipelineChatData' do
    pipeline factory: :ci_empty_pipeline
    chat_name
    response_url { "https://response.com" }
  end
end
