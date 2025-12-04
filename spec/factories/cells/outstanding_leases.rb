# frozen_string_literal: true

FactoryBot.define do
  factory :cells_outstanding_lease, class: 'Cells::OutstandingLease' do
    uuid { SecureRandom.uuid }
    created_at { Time.current }
    updated_at { Time.current }
  end
end
