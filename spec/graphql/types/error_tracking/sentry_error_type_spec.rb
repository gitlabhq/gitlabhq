# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['SentryError'] do
  it { expect(described_class.graphql_name).to eq('SentryError') }

  it 'exposes the expected fields' do
    expected_fields = %i[
      id
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
      sentryProjectId
      sentryProjectName
      sentryProjectSlug
      shortId
      status
      frequency
    ]

    is_expected.to have_graphql_fields(*expected_fields)
  end
end
