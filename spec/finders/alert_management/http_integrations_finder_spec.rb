# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AlertManagement::HttpIntegrationsFinder, feature_category: :incident_management do
  let_it_be(:project) { create(:project) }
  let_it_be_with_reload(:integration) { create(:alert_management_http_integration, project: project) }
  let_it_be(:extra_integration) { create(:alert_management_http_integration, project: project) }
  let_it_be(:prometheus_integration) { create(:alert_management_prometheus_integration, :inactive, project: project) }
  let_it_be(:extra_prometheus_integration) { create(:alert_management_prometheus_integration, project: project) }
  let_it_be(:alt_project_integration) { create(:alert_management_http_integration) }

  let(:params) { {} }

  describe '#execute' do
    subject(:execute) { described_class.new(project, params).execute }

    context 'empty params' do
      it { is_expected.to contain_exactly(integration, prometheus_integration) }
    end

    context 'endpoint_identifier param given' do
      let(:params) { { endpoint_identifier: integration.endpoint_identifier } }

      it { is_expected.to contain_exactly(integration) }

      context 'matches an unavailable integration' do
        let(:params) { { endpoint_identifier: extra_integration.endpoint_identifier } }

        it { is_expected.to be_empty }
      end

      context 'but unknown' do
        let(:params) { { endpoint_identifier: 'unknown' } }

        it { is_expected.to be_empty }
      end

      context 'but blank' do
        let(:params) { { endpoint_identifier: nil } }

        it { is_expected.to contain_exactly(integration, prometheus_integration) }
      end
    end

    context 'active param given' do
      let(:params) { { active: true } }

      it { is_expected.to contain_exactly(integration) }

      context 'but blank' do
        let(:params) { { active: nil } }

        it { is_expected.to contain_exactly(integration, prometheus_integration) }
      end
    end

    context 'type_identifier param given' do
      let(:params) { { type_identifier: extra_integration.type_identifier } }

      it { is_expected.to contain_exactly(integration) }

      context 'matches an unavailable integration' do
        let(:params) { { type_identifier: extra_prometheus_integration.type_identifier } }

        it { is_expected.to contain_exactly(prometheus_integration) }
      end

      context 'but unknown' do
        let(:params) { { type_identifier: :unknown } }

        it { is_expected.to contain_exactly(integration, prometheus_integration) }
      end

      context 'but blank' do
        let(:params) { { type_identifier: nil } }

        it { is_expected.to contain_exactly(integration, prometheus_integration) }
      end
    end

    context 'project has no integrations' do
      subject(:execute) { described_class.new(create(:project), params).execute }

      it { is_expected.to be_empty }
    end
  end
end
