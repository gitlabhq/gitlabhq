# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ClusterAgent'], feature_category: :deployment_management do
  let(:fields) do
    %i[created_at created_by_user id name project updated_at tokens web_path connections activity_events
      user_access_authorizations]
  end

  it { expect(described_class.graphql_name).to eq('ClusterAgent') }

  it { expect(described_class).to require_graphql_authorizations(:read_cluster_agent) }

  it { expect(described_class).to include_graphql_fields(*fields) }

  describe '.authorization_scopes' do
    it 'includes :ai_workflows' do
      expect(described_class.authorization_scopes).to include(:ai_workflows)
    end
  end

  describe 'field scopes' do
    {
      'id' => %i[api read_api ai_workflows],
      'name' => %i[api read_api ai_workflows],
      'webPath' => %i[api read_api ai_workflows]
    }.each do |field, scopes|
      it "includes the correct scopes for #{field}" do
        expect(described_class.fields[field].instance_variable_get(:@scopes)).to include(*scopes)
      end
    end
  end
end
