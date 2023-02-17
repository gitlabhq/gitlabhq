# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::UsageTrendsController do
  let(:admin) { create(:user, :admin) }

  before do
    sign_in(admin)
  end

  describe 'GET #show' do
    it_behaves_like 'tracking unique visits', :index do
      let(:target_id) { 'i_analytics_instance_statistics' }
    end

    it_behaves_like 'Snowplow event tracking with RedisHLL context' do
      subject { get :index }

      let(:category) { described_class.name }
      let(:action) { 'perform_analytics_usage_action' }
      let(:label) { 'redis_hll_counters.analytics.analytics_total_unique_counts_monthly' }
      let(:property) { 'i_analytics_instance_statistics' }
      let(:namespace) { nil }
      let(:project) { nil }
      let(:user) { admin }
    end
  end
end
