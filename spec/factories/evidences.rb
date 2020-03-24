# frozen_string_literal: true

FactoryBot.define do
  factory :evidence, class: 'Releases::Evidence' do
    release
  end
end
