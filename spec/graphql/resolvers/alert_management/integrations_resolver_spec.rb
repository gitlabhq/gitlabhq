# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::AlertManagement::IntegrationsResolver do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:prometheus_integration) { create(:prometheus_service, project: project) }
  let_it_be(:active_http_integration) { create(:alert_management_http_integration, project: project) }
  let_it_be(:inactive_http_integration) { create(:alert_management_http_integration, :inactive, project: project) }
  let_it_be(:other_proj_integration) { create(:alert_management_http_integration) }

  subject { sync(resolve_http_integrations) }

  specify do
    expect(described_class).to have_nullable_graphql_type(Types::AlertManagement::IntegrationType.connection_type)
  end

  context 'user does not have permission' do
    it { is_expected.to be_empty }
  end

  context 'user has permission' do
    before do
      project.add_maintainer(current_user)
    end

    it { is_expected.to contain_exactly(active_http_integration, prometheus_integration) }
  end

  private

  def resolve_http_integrations(args = {}, context = { current_user: current_user })
    resolve(described_class, obj: project, ctx: context)
  end
end
