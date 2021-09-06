# frozen_string_literal: true

FactoryBot.define do
  factory :ci_build_trace_metadata, class: 'Ci::BuildTraceMetadata' do
    build factory: :ci_build
  end
end
