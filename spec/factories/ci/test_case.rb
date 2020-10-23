# frozen_string_literal: true

FactoryBot.define do
  factory :ci_test_case, class: 'Ci::TestCase' do
    project
    key_hash { Digest::SHA256.hexdigest(SecureRandom.hex) }
  end
end
