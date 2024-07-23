# frozen_string_literal: true

FactoryBot.define do
  # This factory is called :namespace but actually maps (and always has) to User type
  # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/74152#note_730034103 for context
  factory :namespace, class: 'Namespaces::UserNamespace' do
    sequence(:name) { |n| "namespace#{n}" }
    type { Namespaces::UserNamespace.sti_name }

    path { name.downcase.gsub(/\s/, '_') }

    owner { association(:user, strategy: :build, namespace: instance, username: path) }

    association :organization

    after(:create) do |namespace, evaluator|
      # simulating ::Namespaces::ProcessSyncEventsWorker because most tests don't run Sidekiq inline
      # Note: we need to get refreshed `traversal_ids` it is updated via SQL query
      #       in `Namespaces::Traversal::Linear#sync_traversal_ids` (see the NOTE in that method).
      #       We cannot use `.reload` because it cleans other on-the-fly attributes.
      namespace.create_ci_namespace_mirror(traversal_ids: Namespace.find(namespace.id).traversal_ids) unless namespace.ci_namespace_mirror
    end

    trait :with_aggregation_schedule do
      after(:create) do |namespace|
        create(:namespace_aggregation_schedules, namespace: namespace)
      end
    end

    trait :with_root_storage_statistics do
      after(:create) do |namespace|
        create(:namespace_root_storage_statistics, namespace: namespace)
      end
    end

    trait :with_namespace_settings do
      after(:create) do |namespace|
        create(:namespace_settings, namespace: namespace)
      end
    end

    trait :allow_runner_registration_token do
      after(:create) do |namespace|
        create(:namespace_settings, namespace: namespace) unless namespace.namespace_settings
        namespace.namespace_settings.update!(allow_runner_registration_token: true)
      end
    end

    trait :shared_runners_disabled do
      shared_runners_enabled { false }
    end
  end
end
