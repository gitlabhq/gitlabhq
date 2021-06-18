# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['AlertManagementPrometheusIntegration'] do
  include GraphqlHelpers

  specify { expect(described_class.graphql_name).to eq('AlertManagementPrometheusIntegration') }
  specify { expect(described_class).to require_graphql_authorizations(:admin_project) }

  describe 'resolvers' do
    shared_examples_for 'has field with value' do |field_name|
      it 'correctly renders the field' do
        result = resolve_field(field_name, integration, current_user: user)

        expect(result).to eq(value)
      end
    end

    let_it_be_with_reload(:integration) { create(:prometheus_integration) }
    let_it_be(:user) { create(:user, maintainer_projects: [integration.project]) }

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

    describe 'a group integration' do
      let_it_be(:group) { create(:group) }
      let_it_be(:integration) { create(:prometheus_integration, project: nil, group: group) }

      # Since it is impossible to authorize the parent here, given that the
      # project is nil, all fields should be redacted:

      described_class.fields.each_key do |field_name|
        context "field: #{field_name}" do
          it 'is redacted' do
            expect do
              resolve_field(field_name, integration, current_user: user)
            end.to raise_error(GraphqlHelpers::UnauthorizedObject)
          end
        end
      end
    end
  end
end
