# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::DeploymentResolver do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository, :private) }
  let_it_be(:environment) { create(:environment, project: project) }
  let_it_be(:deployment) { create(:deployment, :created, environment: environment, project: project) }
  let_it_be(:developer) { create(:user, developer_of: project) }

  let(:current_user) { developer }

  describe '#resolve' do
    it 'finds the deployment' do
      expect(resolve_deployments(iid: deployment.iid)).to contain_exactly(deployment)
    end

    it 'does not find the deployment if the IID does not match' do
      expect(resolve_deployments(iid: non_existing_record_id)).to be_empty
    end
  end

  def resolve_deployments(args = {}, context = { current_user: current_user })
    resolve(described_class, obj: project, args: args, ctx: context)
  end
end
