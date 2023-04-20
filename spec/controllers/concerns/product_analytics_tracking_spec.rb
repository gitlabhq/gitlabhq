# frozen_string_literal: true

require "spec_helper"

RSpec.describe ProductAnalyticsTracking, :snowplow, feature_category: :product_analytics do
  include TrackingHelpers
  include SnowplowHelpers

  let(:user) { create(:user) }
  let(:event_name) { 'an_event' }
  let(:event_action) { 'an_action' }
  let(:event_label) { 'a_label' }

  let!(:group) { create(:group) }
  let_it_be(:project) { create(:project) }

  before do
    allow(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:track_event)
    stub_const("#{described_class}::MIGRATED_EVENTS", ['an_event'])
  end

  controller(ApplicationController) do
    include ProductAnalyticsTracking

    skip_before_action :authenticate_user!, only: :show
    track_event(
      :index,
      :show,
      name: 'an_event',
      action: 'an_action',
      label: 'a_label',
      destinations: [:redis_hll, :snowplow],
      conditions: [:custom_condition_one?, :custom_condition_two?]
    ) { |controller| controller.get_custom_id }

    def index
      render html: 'index'
    end

    def new
      render html: 'new'
    end

    def show
      render html: 'show'
    end

    def get_custom_id
      'some_custom_id'
    end

    private

    def tracking_namespace_source
      Group.first
    end

    def tracking_project_source
      Project.first
    end

    def custom_condition_one?
      true
    end

    def custom_condition_two?
      true
    end
  end

  def expect_redis_hll_tracking
    expect(Gitlab::UsageDataCounters::HLLRedisCounter).to have_received(:track_event)
                                                            .with(event_name, values: instance_of(String))
  end

  def expect_snowplow_tracking(user)
    context = Gitlab::Tracking::ServicePingContext.new(data_source: :redis_hll, event: event_name)
                                                  .to_context.to_json

    expect_snowplow_event(
      category: anything,
      action: event_action,
      property: event_name,
      label: event_label,
      project: project,
      namespace: group,
      user: user,
      context: [context]
    )
  end

  def expect_no_tracking
    expect(Gitlab::UsageDataCounters::HLLRedisCounter).not_to receive(:track_event)

    expect_no_snowplow_event
  end

  context 'when user is logged in' do
    before do
      sign_in(user)
    end

    it 'tracks the event' do
      get :index

      expect_redis_hll_tracking
      expect_snowplow_tracking(user)
    end

    it 'tracks the event if DNT is not enabled' do
      stub_do_not_track('0')

      get :index

      expect_redis_hll_tracking
      expect_snowplow_tracking(user)
    end

    it 'does not track the event if DNT is enabled' do
      stub_do_not_track('1')

      get :index

      expect_no_tracking
    end

    it 'does not track the event if the format is not HTML' do
      get :index, format: :json

      expect_no_tracking
    end

    it 'does not track the event if a custom condition returns false' do
      allow(controller).to receive(:custom_condition_two?).and_return(false)

      get :index

      expect_no_tracking
    end

    it 'does not track the event for untracked actions' do
      get :new

      expect_no_tracking
    end
  end

  context 'when user is not logged in' do
    let(:visitor_id) { SecureRandom.uuid }

    it 'tracks the event when there is a visitor id' do
      cookies[:visitor_id] = { value: visitor_id, expires: 24.months }

      get :show, params: { id: 1 }

      expect_redis_hll_tracking
      expect_snowplow_tracking(nil)
    end
  end

  context 'when user is not logged in and there is no visitor_id' do
    it 'does not track the event' do
      get :index

      expect_no_tracking
    end

    it 'tracks the event when there is custom id' do
      get :show, params: { id: 1 }

      expect_redis_hll_tracking
      expect_snowplow_tracking(nil)
    end

    context 'when there is no custom_id set' do
      before do
        allow(controller).to receive(:get_custom_id).and_return(nil)

        get :show, params: { id: 2 }
      end

      it 'does not track the HLL event' do
        expect(Gitlab::UsageDataCounters::HLLRedisCounter).not_to receive(:track_event)
      end

      it 'tracks Snowplow event' do
        expect_snowplow_tracking(nil)
      end
    end
  end
end
