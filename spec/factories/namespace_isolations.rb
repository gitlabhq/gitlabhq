# frozen_string_literal: true

FactoryBot.define do
  factory :namespace_isolation, class: "Namespaces::NamespaceIsolation" do
    namespace { association(:namespace) }
    isolated { false }

    trait :isolated do
      isolated { true }
    end

    trait :not_isolated do
      isolated { false }
    end
  end
end
