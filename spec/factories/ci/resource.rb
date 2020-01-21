# frozen_string_literal: true

FactoryBot.define do
  factory :ci_resource, class: 'Ci::Resource' do
    resource_group factory: :ci_resource_group

    trait(:retained) do
      build factory: :ci_build
    end
  end
end
