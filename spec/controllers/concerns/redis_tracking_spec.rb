# frozen_string_literal: true

require "spec_helper"

RSpec.describe RedisTracking do
  let(:feature) { 'approval_rule' }
  let(:user) { create(:user) }

  before do
    skip_feature_flags_yaml_validation
  end

  controller(ApplicationController) do
    include RedisTracking

    skip_before_action :authenticate_user!, only: :show
    track_redis_hll_event :index, :show, name: 'g_compliance_approval_rules', feature: :approval_rule, feature_default_enabled: true,
      if: [:custom_condition_one?, :custom_condition_two?]

    def index
      render html: 'index'
    end

    def new
      render html: 'new'
    end

    def show
      render html: 'show'
    end

    private

    def custom_condition_one?
      true
    end

    def custom_condition_two?
      true
    end
  end

  def expect_tracking
    expect(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:track_event)
      .with(instance_of(String), 'g_compliance_approval_rules')
  end

  def expect_no_tracking
    expect(Gitlab::UsageDataCounters::HLLRedisCounter).not_to receive(:track_event)
  end

  context 'with feature disabled' do
    it 'does not track the event' do
      stub_feature_flags(feature => false)

      expect_no_tracking

      get :index
    end
  end

  context 'with feature enabled' do
    before do
      stub_feature_flags(feature => true)
    end

    context 'when user is logged in' do
      before do
        sign_in(user)
      end

      it 'tracks the event' do
        expect_tracking

        get :index
      end

      it 'passes default_enabled flag' do
        expect(controller).to receive(:metric_feature_enabled?).with(feature.to_sym, true)

        get :index
      end

      it 'tracks the event if DNT is not enabled' do
        request.headers['DNT'] = '0'

        expect_tracking

        get :index
      end

      it 'does not track the event if DNT is enabled' do
        request.headers['DNT'] = '1'

        expect_no_tracking

        get :index
      end

      it 'does not track the event if the format is not HTML' do
        expect_no_tracking

        get :index, format: :json
      end

      it 'does not track the event if a custom condition returns false' do
        expect(controller).to receive(:custom_condition_two?).and_return(false)

        expect_no_tracking

        get :index
      end

      it 'does not track the event for untracked actions' do
        expect_no_tracking

        get :new
      end
    end

    context 'when user is not logged in and there is a visitor_id' do
      let(:visitor_id) { SecureRandom.uuid }

      before do
        routes.draw { get 'show' => 'anonymous#show' }
      end

      it 'tracks the event' do
        cookies[:visitor_id] = { value: visitor_id, expires: 24.months }

        expect_tracking

        get :show
      end
    end

    context 'when user is not logged in and there is no visitor_id' do
      it 'does not track the event' do
        expect_no_tracking

        get :index
      end
    end
  end
end
