# frozen_string_literal: true

# These factories should not be called directly unless we are testing a _tracker_data model.
# The factories are used when creating integrations.
FactoryBot.define do
  factory :jira_tracker_data, class: 'Integrations::JiraTrackerData' do
    integration factory: :jira_integration
  end

  factory :zentao_tracker_data, class: 'Integrations::ZentaoTrackerData' do
    integration factory: :zentao_integration
    url { 'https://jihudemo.zentao.net' }
    api_url { '' }
    api_token { 'ZENTAO_TOKEN' }
    zentao_product_xid { '3' }
  end

  factory :issue_tracker_data, class: 'Integrations::IssueTrackerData' do
    integration
  end
end
