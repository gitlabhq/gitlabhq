# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ProjectHook'], feature_category: :webhooks do
  include GraphqlHelpers

  specify { expect(described_class.graphql_name).to eq('ProjectHook') }

  specify { expect(described_class).to require_graphql_authorizations(:read_web_hook) }

  it 'exposes the expected fields' do
    expected_fields = %i[
      id
      url
      name
      description
      createdAt
      enableSslVerification
      alertStatus
      disabledUntil
      urlVariables
      customHeaders
      customWebhookTemplate
      pushEventsBranchFilter
      branchFilterStrategy
      pushEvents
      tagPushEvents
      mergeRequestsEvents
      issuesEvents
      confidentialIssuesEvents
      noteEvents
      confidentialNoteEvents
      pipelineEvents
      wikiPageEvents
      deploymentEvents
      featureFlagEvents
      jobEvents
      releasesEvents
      milestoneEvents
      emojiEvents
      resourceAccessTokenEvents
      webhookEvents
      webhookEvent
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end

  it_behaves_like 'a webhook type' do
    let_it_be_with_reload(:webhook) { create(:project_hook) }
    let_it_be(:current_user) { create(:user, maintainer_of: webhook.project) }
  end
end
