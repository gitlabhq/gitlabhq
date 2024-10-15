# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ReleaseLinks'] do
  it { expect(described_class).to require_graphql_authorizations(:read_release) }

  it 'has the expected fields' do
    expected_fields = %w[
      selfUrl
      openedMergeRequestsUrl
      mergedMergeRequestsUrl
      closedMergeRequestsUrl
      openedIssuesUrl
      closedIssuesUrl
      editUrl
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end

  context 'individual field authorization' do
    def fetch_authorizations(field_name)
      described_class.fields[field_name].instance_variable_get(:@authorize)
    end

    describe 'openedMergeRequestsUrl' do
      it 'has valid authorization' do
        expect(fetch_authorizations('openedMergeRequestsUrl')).to include(:read_code)
      end
    end

    describe 'mergedMergeRequestsUrl' do
      it 'has valid authorization' do
        expect(fetch_authorizations('mergedMergeRequestsUrl')).to include(:read_code)
      end
    end

    describe 'closedMergeRequestsUrl' do
      it 'has valid authorization' do
        expect(fetch_authorizations('closedMergeRequestsUrl')).to include(:read_code)
      end
    end

    describe 'openedIssuesUrl' do
      it 'has valid authorization' do
        expect(fetch_authorizations('openedIssuesUrl')).to include(:read_code)
      end
    end

    describe 'closedIssuesUrl' do
      it 'has valid authorization' do
        expect(fetch_authorizations('closedIssuesUrl')).to include(:read_code)
      end
    end

    describe 'editUrl' do
      it 'has valid authorization' do
        expect(fetch_authorizations('editUrl')).to include(:update_release)
      end
    end
  end
end
