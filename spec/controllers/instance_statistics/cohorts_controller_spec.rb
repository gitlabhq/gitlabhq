# frozen_string_literal: true

require 'spec_helper'

describe InstanceStatistics::CohortsController do
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  it_behaves_like 'instance statistics availability'

  it 'renders a 404 when the usage ping is disabled' do
    stub_application_setting(usage_ping_enabled: false)

    get :index

    expect(response).to have_gitlab_http_status(:not_found)
  end
end
