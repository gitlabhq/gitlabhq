# frozen_string_literal: true

require "spec_helper"

RSpec.describe RedisTracking do
  let(:feature) { 'approval_rule' }
  let(:user) { create(:user) }

  controller(ApplicationController) do
    include RedisTracking

    skip_before_action :authenticate_user!, only: :show
    track_redis_hll_event :index, :show, name: 'g_compliance_approval_rules', feature: :approval_rule, feature_default_enabled: true

    def index
      render html: 'index'
    end

    def new
      render html: 'new'
    end

    def show
      render html: 'show'
    end
  end

  context 'with feature disabled' do
    it 'does not track the event' do
      stub_feature_flags(feature => false)

      expect(Gitlab::UsageDataCounters::HLLRedisCounter).not_to receive(:track_event)

      get :index
    end
  end

  context 'with feature enabled' do
    before do
      stub_feature_flags(feature => true)
    end

    context 'when user is logged in' do
      it 'tracks the event' do
        sign_in(user)

        expect(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:track_event)

        get :index
      end

      it 'passes default_enabled flag' do
        sign_in(user)

        expect(controller).to receive(:metric_feature_enabled?).with(feature.to_sym, true)

        get :index
      end
    end

    context 'when user is not logged in and there is a visitor_id' do
      let(:visitor_id) { SecureRandom.uuid }

      before do
        routes.draw { get 'show' => 'anonymous#show' }
      end

      it 'tracks the event' do
        cookies[:visitor_id] = { value: visitor_id, expires: 24.months }

        expect(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:track_event)

        get :show
      end
    end

    context 'when user is not logged in and there is no visitor_id' do
      it 'does not tracks the event' do
        expect(Gitlab::UsageDataCounters::HLLRedisCounter).not_to receive(:track_event)

        get :index
      end
    end

    context 'for untracked action' do
      it 'does not tracks the event' do
        expect(Gitlab::UsageDataCounters::HLLRedisCounter).not_to receive(:track_event)

        get :new
      end
    end
  end
end
