# frozen_string_literal: true

FactoryBot.define do
  factory :ci_build_pending_state, class: 'Ci::BuildPendingState' do
    build factory: :ci_build
    trace_checksum { 'crc32:bc614e' }
    state { 'success' }
  end
end
