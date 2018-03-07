FactoryBot.define do
  factory :service do
    project
    type 'Service'
  end

  factory :custom_issue_tracker_service, class: CustomIssueTrackerService do
    project
    type 'CustomIssueTrackerService'
    category 'issue_tracker'
    active true
    properties(
      project_url: 'https://project.url.com',
      issues_url: 'https://issues.url.com',
      new_issue_url: 'https://newissue.url.com'
    )
  end

  factory :kubernetes_service do
    project
    type 'KubernetesService'
    active true
    properties({
      api_url: 'https://kubernetes.example.com',
      token: 'a' * 40
    })
  end

  factory :prometheus_service do
    project
    active true
    properties({
      api_url: 'https://prometheus.example.com/',
      manual_configuration: true
    })
  end

  factory :jira_service do
    project
    active true
    properties(
      url: 'https://jira.example.com',
      username: 'jira_user',
      password: 'my-secret-password',
      project_key: 'jira-key'
    )
  end

  factory :hipchat_service do
    project
    type 'HipchatService'
    token 'test_token'
  end
end
