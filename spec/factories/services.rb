FactoryBot.define do
  factory :service do
    project
    type 'Service'
  end

  factory :custom_issue_tracker_service, class: CustomIssueTrackerService do
    project
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

    skip_deprecation_validation true
  end

  factory :mock_deployment_service do
    project
    type 'MockDeploymentService'
    active true
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

  factory :bugzilla_service do
    project
    active true
    issue_tracker
  end

  factory :redmine_service do
    project
    active true
    issue_tracker
  end

  factory :youtrack_service do
    project
    active true
    issue_tracker
  end

  factory :gitlab_issue_tracker_service do
    project
    active true
    issue_tracker
  end

  trait :issue_tracker do
    properties(
      project_url: 'http://issue-tracker.example.com',
      issues_url: 'http://issue-tracker.example.com',
      new_issue_url: 'http://issue-tracker.example.com'
    )
  end

  factory :jira_cloud_service, class: JiraService do
    project
    active true
    properties(
      url: 'https://mysite.atlassian.net',
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
