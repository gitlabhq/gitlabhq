# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::AvatarsController do
  include ExternalAuthorizationServiceHelpers

  let(:user)  { create(:user) }
  let(:group) { create(:group, avatar: fixture_file_upload("spec/fixtures/dk.png", "image/png")) }

  before do
    group.add_owner(user)
    sign_in(user)
  end

  it 'removes avatar from DB calling destroy' do
    delete :destroy, params: { group_id: group.path }
    @group = assigns(:group)
    expect(@group.avatar.present?).to be_falsey
    expect(@group).to be_valid
  end

  it 'works when external authorization service is enabled' do
    enable_external_authorization_service_check

    delete :destroy, params: { group_id: group }

    expect(response).to have_gitlab_http_status(:found)
  end
end
