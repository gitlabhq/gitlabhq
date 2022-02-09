# frozen_string_literal: true

FactoryBot.define do
  factory :namespace_statistics do
    namespace factory: :namespace
  end
end
