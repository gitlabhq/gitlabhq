# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Clusters::AgentUrlConfigurations::Delete, feature_category: :deployment_management do
  include GraphqlHelpers

  let_it_be(:url_configuration) { create(:cluster_agent_url_configuration) }
  let_it_be(:current_user) { create(:user) }

  let(:mutation) do
    described_class.new(
      object: double,
      context: query_context,
      field: double
    )
  end

  it { expect(described_class.graphql_name).to eq('ClusterAgentUrlConfigurationDelete') }
  it { expect(described_class).to require_graphql_authorizations(:admin_cluster) }

  describe '#resolve' do
    let(:global_id) { url_configuration.to_global_id }

    subject(:mutate) { mutation.resolve(id: global_id) }

    context 'when receptive agents are enabled' do
      before do
        stub_application_setting(receptive_cluster_agents_enabled: true)
      end

      context 'when user does not have permission' do
        it 'does not delete the URL configuration' do
          expect { mutate }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
          expect { url_configuration.reload }.not_to raise_error
        end
      end

      context 'when user has permission' do
        before do
          url_configuration.agent.project.add_maintainer(current_user)
        end

        it 'deletes the URL configuration' do
          expect { mutate }.to change { ::Clusters::Agents::UrlConfiguration.count }.by(-1)
          expect { url_configuration.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    context 'when receptive agents are disabled' do
      before do
        stub_application_setting(receptive_cluster_agents_enabled: false)
        url_configuration.agent.project.add_maintainer(current_user)
      end

      it 'raises an error' do
        expect { mutate }.not_to change { ::Clusters::Agents::UrlConfiguration.count }
        expect { url_configuration.reload }.not_to raise_error
        expect(mutate[:errors]).to eq(["Receptive agents are disabled for this GitLab instance"])
      end
    end
  end
end
