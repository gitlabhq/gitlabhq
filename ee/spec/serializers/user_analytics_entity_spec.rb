require 'spec_helper'

describe UserAnalyticsEntity do
  let(:user) { build_stubbed(:user) }
  let(:events) do
    {
      push: {},
      issues_created: {},
      issues_closed: {},
      merge_requests_created: {},
      merge_requests_merged: {},
      total_events: {}
    }
  end
  let(:request) { double('request') }

  subject(:json) { described_class.new(user, request: request).as_json }

  before do
    allow(request).to receive(:events).and_return(events)
  end

  it 'has all the user attributes' do
    is_expected.to include(:username, :fullname, :user_web_url)
  end

  [:push, :issues_created, :issues_closed, :merge_requests_created,
   :merge_requests_merged, :total_events].each do |event_type|
    it "fetches #{event_type} events for the user from the request" do
      events[event_type] = { user.id => 42 }

      expect(json[event_type]).to eq(42)
    end
  end

  it 'sets 0 as the total when there were no events for a type' do
    expect(json[:total_events]).to eq(0)
  end
end
