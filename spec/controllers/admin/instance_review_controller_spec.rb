# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::InstanceReviewController, feature_category: :service_ping do
  include UsageDataHelpers

  let(:admin) { create(:admin) }
  let(:subscriptions_instance_review_url) { ::Gitlab::Routing.url_helpers.subscription_portal_instance_review_url }

  before do
    sign_in(admin)
  end

  context 'GET #index' do
    subject { post :index }

    context 'with usage ping enabled', :with_license do
      let(:service_ping_data) do
        {
          version: ::Gitlab::VERSION,
          active_user_count: 5,
          counts: {
            projects: 2,
            groups: 1,
            issues: 0,
            merge_requests: 0,
            ci_internal_pipelines: 0,
            ci_external_pipelines: 0,
            labels: 0,
            milestones: 0,
            snippets: 0,
            notes: 0
          },
          licensee: { Name: admin.name, Email: admin.email }
        }
      end

      before do
        stub_application_setting(usage_ping_enabled: true)
        stub_usage_data_connections
        stub_database_flavor_check
      end

      it 'redirects to the customers app with correct params' do
        params = { instance_review: {
          email: admin.email,
          last_name: admin.name,
          version: ::Gitlab::VERSION,
          users_count: 5,
          projects_count: 2,
          groups_count: 1,
          issues_count: 0,
          merge_requests_count: 0,
          internal_pipelines_count: 0,
          external_pipelines_count: 0,
          labels_count: 0,
          milestones_count: 0,
          snippets_count: 0,
          notes_count: 0
        } }.to_query

        expect(::Gitlab::Usage::ServicePingReport).to receive(:for).with(output: :all_metrics_values,
          cached: true).and_return(service_ping_data)

        subject

        expect(response).to redirect_to("#{subscriptions_instance_review_url}?#{params}")
      end
    end

    context 'with usage ping disabled' do
      before do
        stub_application_setting(usage_ping_enabled: false)
        subject
      end

      it 'redirects to the customers app with correct params' do
        params = { instance_review: {
          email: admin.email,
          last_name: admin.name,
          version: ::Gitlab::VERSION
        } }.to_query

        expect(response).to redirect_to("#{subscriptions_instance_review_url}?#{params}")
      end
    end
  end
end
