require 'spec_helper'

describe Groups::AvatarsController do
  include ExternalAuthorizationServiceHelpers

  let(:user)  { create(:user) }
  let(:group) { create(:group, avatar: fixture_file_upload(Rails.root + "spec/fixtures/dk.png", "image/png")) }

  before do
    group.add_owner(user)
    sign_in(user)
  end

  it 'works when external authorization service is enabled' do
    enable_external_authorization_service_check

    delete :destroy, group_id: group

    expect(response).to have_gitlab_http_status(302)
  end
end
