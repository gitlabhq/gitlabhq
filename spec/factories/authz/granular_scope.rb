# frozen_string_literal: true

FactoryBot.define do
  factory :granular_scope, class: 'Authz::GranularScope' do
    organization
    namespace
  end
end
