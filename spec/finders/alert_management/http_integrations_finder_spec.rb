# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AlertManagement::HttpIntegrationsFinder do
  let_it_be(:project) { create(:project) }
  let_it_be_with_reload(:integration) { create(:alert_management_http_integration, project: project ) }
  let_it_be(:extra_integration) { create(:alert_management_http_integration, project: project ) }
  let_it_be(:alt_project_integration) { create(:alert_management_http_integration) }

  let(:params) { {} }

  describe '#execute' do
    subject(:execute) { described_class.new(project, params).execute }

    context 'empty params' do
      it { is_expected.to contain_exactly(integration) }
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

        it { is_expected.to contain_exactly(integration) }
      end
    end

    context 'active param given' do
      let(:params) { { active: true } }

      it { is_expected.to contain_exactly(integration) }

      context 'when integration is disabled' do
        before do
          integration.update!(active: false)
        end

        it { is_expected.to be_empty }
      end

      context 'but blank' do
        let(:params) { { active: nil } }

        it { is_expected.to contain_exactly(integration) }
      end
    end

    context 'project has no integrations' do
      subject(:execute) { described_class.new(create(:project), params).execute }

      it { is_expected.to be_empty }
    end
  end
end
