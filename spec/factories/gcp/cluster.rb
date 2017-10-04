FactoryGirl.define do
  factory :gcp_cluster, class: Gcp::Cluster do
    project
    user
    enabled true
    gcp_project_id 'gcp-project-12345'
    gcp_cluster_name 'test-cluster'
    gcp_cluster_zone 'us-central1-a'
    gcp_cluster_size 1

    trait :with_kubernetes_service do
      service :kubernetes_service
    end

    trait :created_on_gke do
      status_event :make_created
      endpoint '111.111.111.111'
      ca_cert 'xxxxxx'
      kubernetes_token 'xxxxxx'
      username 'xxxxxx'
      password 'xxxxxx'
    end

    trait :errored do
      status_event :make_errored
      status_reason 'general error'
    end
  end
end
