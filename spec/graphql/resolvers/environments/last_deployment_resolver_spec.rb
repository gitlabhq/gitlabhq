# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Environments::LastDeploymentResolver do
  include GraphqlHelpers
  include Gitlab::Graphql::Laziness

  let_it_be(:project) { create(:project, :repository, :private) }
  let_it_be(:environment) { create(:environment, project: project) }
  let_it_be(:deployment) { create(:deployment, :created, environment: environment, project: project) }
  let_it_be(:developer) { create(:user, developer_of: project) }

  let(:current_user) { developer }

  describe '#resolve' do
    it 'finds the deployment when status matches' do
      expect(resolve_last_deployment(status: :created)).to eq(deployment)
    end

    it 'does not find the deployment when status does not match' do
      expect(resolve_last_deployment(status: :success)).to be_nil
    end

    it 'raises an error when status is not specified' do
      expect { resolve_last_deployment }.to raise_error(ArgumentError)
    end

    it 'raises an error when status is not supported' do
      expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ArgumentError,
        '"skipped" status is not supported.') do
        resolve_last_deployment(status: :skipped)
      end
    end
  end

  def resolve_last_deployment(args = {}, context = { current_user: current_user })
    force(resolve(described_class, obj: environment, ctx: context, args: args))
  end
end
