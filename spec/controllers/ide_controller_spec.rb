# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IdeController do
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  it 'increases the views counter' do
    expect(Gitlab::UsageDataCounters::WebIdeCounter).to receive(:increment_views_count)

    get :index
  end
end
