# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['AlertManagementPrometheusIntegration'], feature_category: :incident_management do
  include GraphqlHelpers

  specify { expect(described_class.graphql_name).to eq('AlertManagementPrometheusIntegration') }
  specify { expect(described_class).to require_graphql_authorizations(:admin_operations) }

  describe 'resolvers' do
    shared_examples_for 'has field with value' do |field_name|
      it 'correctly renders the field' do
        result = resolve_field(field_name, integration, current_user: user)

        expect(result).to eq(value)
      end
    end

    let_it_be_with_reload(:integration) { create(:alert_management_prometheus_integration, :legacy) }
    let_it_be(:user) { create(:user, maintainer_of: integration.project) }

    it_behaves_like 'has field with value', 'name' do
      let(:value) { integration.name }
    end

    it_behaves_like 'has field with value', 'type' do
      let(:value) { :prometheus }
    end

    it_behaves_like 'has field with value', 'token' do
      let(:value) { integration.token }
    end

    it_behaves_like 'has field with value', 'url' do
      let(:value) { "http://localhost/#{integration.project.full_path}/prometheus/alerts/notify.json" }
    end

    it_behaves_like 'has field with value', 'active' do
      let(:value) { integration.active }
    end
  end
end
