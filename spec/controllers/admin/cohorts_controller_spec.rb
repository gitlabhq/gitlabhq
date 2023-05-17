# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::CohortsController do
  let(:user) { create(:admin) }

  before do
    sign_in(user)
  end

  describe 'GET #index' do
    it_behaves_like 'tracking unique visits', :index do
      let(:target_id) { 'i_analytics_cohorts' }
    end

    it_behaves_like 'Snowplow event tracking with RedisHLL context' do
      subject { get :index }

      let(:category) { described_class.name }
      let(:action) { 'perform_analytics_usage_action' }
      let(:label) { 'redis_hll_counters.analytics.analytics_total_unique_counts_monthly' }
      let(:property) { 'i_analytics_cohorts' }
      let(:namespace) { nil }
      let(:project) { nil }
    end
  end
end
