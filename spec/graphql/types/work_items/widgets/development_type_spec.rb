# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::WorkItems::Widgets::DevelopmentType, feature_category: :team_planning do
  it 'exposes the expected fields' do
    expected_fields = %i[type related_branches closing_merge_requests closing_merge_requests_count
      related_merge_requests will_auto_close_by_merge_request]

    expect(described_class).to have_graphql_fields(expected_fields).at_least
  end

  describe 'closing_merge_requests_count' do
    it 'resolves through the batched resolver the connection count already uses' do
      expect(described_class.fields['closingMergeRequestsCount'].resolver)
        .to eq(::Resolvers::MergeRequestsCountResolver)
    end

    it 'is cheaper than the connection it replaces for the list' do
      expect(described_class.fields['closingMergeRequestsCount'].complexity).to eq(1)
      expect(described_class.fields['closingMergeRequests'].complexity).to eq(10)
    end
  end

  describe 'fields with :ai_workflows scope' do
    it 'includes :ai_workflows scope for the applicable fields' do
      related_merge_requests_field = described_class.fields['relatedMergeRequests']
      expect(related_merge_requests_field.instance_variable_get(:@scopes)).to include(:ai_workflows)
    end
  end

  describe 'authorization_scopes' do
    it 'includes :ai_workflows scope' do
      expect(described_class.authorization_scopes).to include(:ai_workflows)
    end
  end
end
