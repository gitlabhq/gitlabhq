# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['AlertManagementPrometheusIntegration'] do
  include GraphqlHelpers

  specify { expect(described_class.graphql_name).to eq('AlertManagementPrometheusIntegration') }
  specify { expect(described_class).to require_graphql_authorizations(:admin_project) }

  describe 'resolvers' do
    shared_examples_for 'has field with value' do |field_name|
      it 'correctly renders the field' do
        expect(resolve_field(field_name, integration)).to eq(value)
      end
    end

    let_it_be_with_reload(:integration) { create(:prometheus_service) }

    it_behaves_like 'has field with value', 'name' do
      let(:value) { integration.title }
    end

    it_behaves_like 'has field with value', 'type' do
      let(:value) { :prometheus }
    end

    it_behaves_like 'has field with value', 'token' do
      let(:value) { nil }
    end

    it_behaves_like 'has field with value', 'url' do
      let(:value) { "http://localhost/#{integration.project.full_path}/prometheus/alerts/notify.json" }
    end

    it_behaves_like 'has field with value', 'active' do
      let(:value) { integration.manual_configuration? }
    end

    context 'with alerting setting' do
      let_it_be(:alerting_setting) { create(:project_alerting_setting, project: integration.project) }

      it_behaves_like 'has field with value', 'token' do
        let(:value) { alerting_setting.token }
      end
    end

    context 'without project' do
      let_it_be(:integration) { create(:prometheus_service, project: nil, group: create(:group)) }

      it_behaves_like 'has field with value', 'token' do
        let(:value) { nil }
      end

      it_behaves_like 'has field with value', 'url' do
        let(:value) { nil }
      end
    end
  end
end
