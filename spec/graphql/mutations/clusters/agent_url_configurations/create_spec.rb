# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Clusters::AgentUrlConfigurations::Create, feature_category: :deployment_management do
  include GraphqlHelpers

  let_it_be(:cluster_agent) { create(:cluster_agent) }
  let_it_be(:current_user) { create(:user) }

  subject(:mutation) { described_class.new(object: nil, context: query_context, field: nil) }

  specify { expect(described_class).to require_graphql_authorizations(:create_cluster) }

  describe '#resolve' do
    let(:url) { 'grpcs://localhost:1111' }

    subject(:mutate) { mutation.resolve(cluster_agent_id: cluster_agent.to_global_id, url: url) }

    context 'when receptive agents are enabled' do
      before do
        stub_application_setting(receptive_cluster_agents_enabled: true)
      end

      context 'without permissions' do
        it 'raises an error if the resource is not accessible to the user' do
          expect { mutate }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end

      context 'with user permissions' do
        before do
          cluster_agent.project.add_maintainer(current_user)
        end

        context 'when using JWT auth' do
          it 'creates a new URL configuration', :aggregate_failures do
            expect { mutate }.to change { ::Clusters::Agents::UrlConfiguration.count }.by(1)
            expect(mutate[:errors]).to eq([])
            expect(mutate[:url_configuration].url).to eq(url)
            expect(mutate[:url_configuration].public_key).to be_truthy
          end
        end

        context 'when using mTLS auth' do
          let(:client_cert) { File.read(Rails.root.join('spec/fixtures/clusters/sample_cert.pem')) }
          let(:client_key) { File.read(Rails.root.join('spec/fixtures/clusters/sample_key.key')) }

          subject(:mutate) do
            mutation.resolve(
              cluster_agent_id: cluster_agent.to_global_id,
              url: url,
              client_cert: Base64.encode64(client_cert),
              client_key: Base64.encode64(client_key)
            )
          end

          it 'creates a new URL configuration', :aggregate_failures do
            expect { mutate }.to change { ::Clusters::Agents::UrlConfiguration.count }.by(1)
            expect(mutate[:errors]).to eq([])
            expect(mutate[:url_configuration].url).to eq(url)
            expect(mutate[:url_configuration].client_cert).to eq(client_cert)
          end
        end

        context 'when configuring CA cert and tls host' do
          let(:ca_cert) { File.read(Rails.root.join('spec/fixtures/clusters/sample_cert.pem')) }
          let(:tls_host) { 'gitlab.example.com' }

          subject(:mutate) do
            mutation.resolve(
              cluster_agent_id: cluster_agent.to_global_id,
              url: url,
              ca_cert: Base64.encode64(ca_cert),
              tls_host: tls_host
            )
          end

          it 'creates a new URL configuration', :aggregate_failures do
            expect { mutate }.to change { ::Clusters::Agents::UrlConfiguration.count }.by(1)
            expect(mutate[:errors]).to eq([])
            expect(mutate[:url_configuration].ca_cert).to eq(ca_cert)
            expect(mutate[:url_configuration].tls_host).to eq(tls_host)
          end
        end

        context 'when the agent URL configuration limit is reached' do
          before do
            create(:cluster_agent_url_configuration, agent: cluster_agent)
          end

          it 'raises an error' do
            expect { mutate }.not_to change { ::Clusters::Agents::UrlConfiguration.count }
            expect(mutate[:errors]).to eq(["URL configuration already exists for this agent"])
          end
        end
      end
    end

    context 'when receptive agents are disabled' do
      before do
        stub_application_setting(receptive_cluster_agents_enabled: false)
        cluster_agent.project.add_maintainer(current_user)
      end

      it 'raises an error' do
        expect { mutate }.not_to change { ::Clusters::Agents::UrlConfiguration.count }
        expect(mutate[:errors]).to eq(["Receptive agents are disabled for this GitLab instance"])
      end
    end
  end
end
