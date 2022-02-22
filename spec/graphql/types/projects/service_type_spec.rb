# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Projects::ServiceType do
  specify { expect(described_class).to have_graphql_fields(:type, :service_type, :active) }

  describe ".resolve_type" do
    it 'resolves the corresponding type for objects' do
      expect(described_class.resolve_type(build(:jira_integration), {})).to eq(Types::Projects::Services::JiraServiceType)
      expect(described_class.resolve_type(build(:integration), {})).to eq(Types::Projects::Services::BaseServiceType)
      expect(described_class.resolve_type(build(:drone_ci_integration), {})).to eq(Types::Projects::Services::BaseServiceType)
      expect(described_class.resolve_type(build(:custom_issue_tracker_integration), {})).to eq(Types::Projects::Services::BaseServiceType)
    end
  end
end
