# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Environments::Update, feature_category: :environment_management do
  include GraphqlHelpers
  let_it_be(:project) { create(:project) }
  let_it_be(:environment) { create(:environment, project: project) }
  let_it_be(:maintainer) { create(:user, maintainer_of: project) }
  let_it_be(:reporter) { create(:user, reporter_of: project) }

  let(:current_user) { maintainer }

  subject(:mutation) { described_class.new(object: nil, context: query_context, field: nil) }

  describe '#resolve' do
    subject { mutation.resolve(id: environment_id, **kwargs) }

    let(:environment_id) { environment.to_global_id }
    let(:kwargs) { { external_url: 'https://gitlab.com/' } }

    context 'when service execution succeeded' do
      it 'returns no errors' do
        expect(subject[:errors]).to be_empty
      end

      it 'updates the environment' do
        expect(subject[:environment][:external_url]).to eq('https://gitlab.com/')
      end
    end

    context 'when service cannot update the attribute' do
      let(:kwargs) { { external_url: 'http://${URL}' } }

      it 'returns an error' do
        expect(subject)
          .to eq({
            environment: environment,
            errors: ['External url URI is invalid']
          })
      end
    end

    context 'when setting cluster agent ID to the environment' do
      let_it_be(:cluster_agent) { create(:cluster_agent, project: project) }

      let!(:authorization) { create(:agent_user_access_project_authorization, project: project, agent: cluster_agent) }

      let(:kwargs) { { cluster_agent_id: cluster_agent.to_global_id } }

      it 'sets the cluster agent to the environment' do
        expect(subject[:environment].cluster_agent).to eq(cluster_agent)
      end
    end

    context 'when unsetting cluster agent ID to the environment' do
      let_it_be(:cluster_agent) { create(:cluster_agent, project: project) }

      let(:kwargs) { { cluster_agent_id: nil } }

      before do
        environment.update!(cluster_agent: cluster_agent)
      end

      it 'removes the cluster agent from the environment' do
        expect(subject[:environment].cluster_agent).to be_nil
      end
    end

    context 'when the cluster agent is not updated' do
      let_it_be(:cluster_agent) { create(:cluster_agent, project: project) }

      let(:kwargs) { { external_url: 'https://dev.gitlab.com/' } }

      before do
        environment.update!(cluster_agent: cluster_agent)
      end

      it 'does not change the environment cluster agent' do
        expect(subject[:environment].cluster_agent).to eq(cluster_agent)
      end
    end

    context 'when user is reporter who does not have permission to access the environment' do
      let(:current_user) { reporter }

      it 'raises an error' do
        expect { subject }.to raise_error(Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR)
      end
    end
  end
end
