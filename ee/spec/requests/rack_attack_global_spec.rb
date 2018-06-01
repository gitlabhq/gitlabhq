require 'spec_helper'

describe 'Rack Attack global throttles' do
  around do |example|
    # Instead of test environment's :null_store so the throttles can increment
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

    # Make time-dependent tests deterministic
    Timecop.freeze { example.run }

    Rack::Attack.cache.store = Rails.cache
  end

  context 'when the request is from Geo secondary' do
    let(:project) { create(:project) }
    let(:requests_per_period) { 1 }

    before do
      settings_to_set = {
        throttle_unauthenticated_requests_per_period: requests_per_period,
        throttle_unauthenticated_enabled:  true
      }
      stub_application_setting(settings_to_set)
    end

    it 'allows requests over the rate limit' do
      (1 + requests_per_period).times do
        get "/#{project.full_path}.git/info/refs", { service: 'git-upload-pack' }, { 'Authorization' => "#{::Gitlab::Geo::BaseRequest::GITLAB_GEO_AUTH_TOKEN_TYPE} token" }
        expect(response).to have_http_status 401
      end
    end
  end
end
