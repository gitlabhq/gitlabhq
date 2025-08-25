# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ProjectStatisticsRedirect'], feature_category: :consumables_cost_management do
  it 'has all the required fields' do
    expect(described_class).to have_graphql_fields(:repository, :build_artifacts, :packages,
      :wiki, :snippets, :container_registry)
  end

  describe '.authorization_scopes' do
    it 'allows ai_workflows scope token' do
      expect(described_class.authorization_scopes).to include(:ai_workflows)
    end
  end

  describe 'fields with :ai_workflows scope' do
    it "includes :ai_workflows scope for the 'repository' field" do
      field = described_class.fields['repository']
      expect(field.instance_variable_get(:@scopes)).to include(:ai_workflows)
    end
  end
end
