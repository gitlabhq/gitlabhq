# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::InstanceReviewController do
  include UsageDataHelpers

  let(:admin) { create(:admin) }
  let(:subscriptions_url) { ::Gitlab::SubscriptionPortal::SUBSCRIPTIONS_URL }

  before do
    sign_in(admin)
  end

  context 'GET #index' do
    let!(:group) { create(:group) }
    let!(:projects) { create_list(:project, 2, group: group) }

    subject { post :index }

    context 'with usage ping enabled' do
      before do
        stub_application_setting(usage_ping_enabled: true)
        stub_usage_data_connections
        ::Gitlab::UsageData.data(force_refresh: true)
        subject
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

        expect(response).to redirect_to("#{subscriptions_url}/instance_review?#{params}")
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

        expect(response).to redirect_to("#{subscriptions_url}/instance_review?#{params}")
      end
    end
  end
end
