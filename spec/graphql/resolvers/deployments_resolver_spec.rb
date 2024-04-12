# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::DeploymentsResolver do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository, :private) }
  let_it_be(:environment) { create(:environment, project: project) }
  let_it_be(:deployment) { create(:deployment, :created, environment: environment, project: project) }
  let_it_be(:developer) { create(:user, developer_of: project) }

  let(:current_user) { developer }

  describe '#resolve' do
    it 'finds the deployment' do
      expect(resolve_deployments).to contain_exactly(deployment)
    end

    it 'finds the deployment when status matches' do
      expect(resolve_deployments(statuses: [:created])).to contain_exactly(deployment)
    end

    it 'does not find the deployment when status does not match' do
      expect(resolve_deployments(statuses: [:success])).to be_empty
    end

    it 'transforms order_by for finder' do
      expect(DeploymentsFinder)
        .to receive(:new)
        .with(environment: environment.id, status: ['success'], order_by: 'finished_at', sort: 'asc')
        .and_call_original

      resolve_deployments(statuses: [:success], order_by: { finished_at: :asc })
    end
  end

  def resolve_deployments(args = {}, context = { current_user: current_user })
    resolve(described_class, obj: environment, args: args, ctx: context)
  end
end
