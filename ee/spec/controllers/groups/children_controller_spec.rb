require 'spec_helper'

describe Groups::ChildrenController do
  include ExternalAuthorizationServiceHelpers

  let(:user)  { create(:user) }
  let(:group) { create(:group) }

  before do
    group.add_owner(user)
    sign_in(user)
  end

  it 'works when external authorization service is enabled' do
    enable_external_authorization_service_check

    get :index, group_id: group, format: :json

    expect(response).to have_gitlab_http_status(200)
  end
end
