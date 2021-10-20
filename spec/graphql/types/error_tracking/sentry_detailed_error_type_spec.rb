# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['SentryDetailedError'] do
  specify { expect(described_class.graphql_name).to eq('SentryDetailedError') }

  specify { expect(described_class).to require_graphql_authorizations(:read_sentry_issue) }

  it 'exposes the expected fields' do
    expected_fields = %i[
      id
      integrated
      sentryId
      title
      type
      userCount
      count
      firstSeen
      lastSeen
      message
      culprit
      externalUrl
      externalBaseUrl
      sentryProjectId
      sentryProjectName
      sentryProjectSlug
      shortId
      status
      frequency
      firstReleaseLastCommit
      lastReleaseLastCommit
      firstReleaseShortVersion
      lastReleaseShortVersion
      firstReleaseVersion
      lastReleaseVersion
      gitlabIssuePath
      gitlabCommit
      gitlabCommitPath
      tags
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
