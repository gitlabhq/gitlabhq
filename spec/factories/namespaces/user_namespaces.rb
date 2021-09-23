# frozen_string_literal: true

FactoryBot.define do
  factory :user_namespace, class: 'Namespaces::UserNamespace', parent: :namespace do
    sequence(:name) { |n| "user_namespace#{n}" }
    type { Namespaces::UserNamespace.sti_name }
  end
end
