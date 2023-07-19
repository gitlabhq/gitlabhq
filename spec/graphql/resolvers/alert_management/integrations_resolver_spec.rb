# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::AlertManagement::IntegrationsResolver, feature_category: :incident_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:project2) { create(:project) }
  let_it_be(:prometheus_integration) { create(:prometheus_integration, project: project) }
  let_it_be(:active_http_integration) { create(:alert_management_http_integration, project: project) }
  let_it_be(:inactive_http_integration) { create(:alert_management_http_integration, :inactive, project: project) }
  let_it_be(:other_proj_integration) { create(:alert_management_http_integration, project: project2) }
  let_it_be(:other_proj_prometheus_integration) { create(:prometheus_integration, project: project2) }
  let_it_be(:migrated_integration) { create(:alert_management_prometheus_integration, :legacy, project: project) }

  let(:params) { {} }

  subject { sync(resolve_http_integrations(params)) }

  specify do
    expect(described_class).to have_nullable_graphql_type(Types::AlertManagement::IntegrationType.connection_type)
  end

  context 'user does not have permission' do
    it { is_expected.to be_empty }
  end

  context 'user has permission' do
    before do
      project.add_maintainer(current_user)
      project2.add_maintainer(current_user)
    end

    it { is_expected.to contain_exactly(active_http_integration, prometheus_integration) }

    context 'when HTTP Integration ID is given' do
      context 'when integration is from the current project' do
        let(:params) { { id: global_id_of(inactive_http_integration) } }

        it { is_expected.to contain_exactly(inactive_http_integration) }
      end

      context 'when integration is from other project' do
        let(:params) { { id: global_id_of(other_proj_integration) } }

        it { is_expected.to be_empty }
      end
    end

    context 'when Prometheus Integration ID is given' do
      context 'when integration is from the current project' do
        let(:params) { { id: global_id_of(prometheus_integration) } }

        it { is_expected.to contain_exactly(prometheus_integration) }
      end

      context 'when integration is from other project' do
        let(:params) { { id: global_id_of(other_proj_prometheus_integration) } }

        it { is_expected.to be_empty }
      end
    end
  end

  private

  def resolve_http_integrations(args = {}, context = { current_user: current_user })
    resolve(described_class, obj: project, args: args, ctx: context)
  end
end
