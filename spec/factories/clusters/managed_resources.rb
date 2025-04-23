# frozen_string_literal: true

FactoryBot.define do
  factory :managed_resource, class: 'Clusters::Agents::ManagedResource' do
    project
    environment
    association :cluster_agent
    association :build, factory: :ci_build
    deletion_strategy { :on_stop }

    tracked_objects do
      [
        {
          'kind' => 'Namespace',
          'name' => 'production',
          'group' => '',
          'version' => 'v1',
          'namespace' => ''
        },
        {
          'kind' => 'RoleBinding',
          'name' => 'bind-ci-job-production',
          'group' => 'rbac.authorization.k8s.io',
          'version' => 'v1',
          'namespace' => 'production'
        }
      ]
    end

    trait :completed do
      status { :completed }
    end
  end
end
