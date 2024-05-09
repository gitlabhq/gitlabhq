# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::GroupsController, '(JavaScript fixtures)', type: :controller, feature_category: :cell do
  include JavaScriptFixturesHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:organization) { create(:organization) }
  let_it_be(:organization_user) { create(:organization_user, organization: organization, user: current_user) }

  before do
    sign_in(current_user)
  end

  it 'controller/organizations/groups/post.json' do
    post :create, params: {
      organization_path: organization.path,
      group: {
        name: 'Foo bar',
        path: 'foo-bar',
        visibility_level: Gitlab::VisibilityLevel::INTERNAL
      }
    }, format: :json

    expect(response).to be_successful
  end
end
