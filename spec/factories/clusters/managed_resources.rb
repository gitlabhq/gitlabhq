# frozen_string_literal: true

FactoryBot.define do
  factory :managed_resource, class: 'Clusters::Agents::ManagedResource' do
    project
    environment { association(:environment, project: project) }
    cluster_agent { association(:cluster_agent, project: project) }
    build { association(:ci_build, project: project) }
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
