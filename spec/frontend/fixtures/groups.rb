require 'spec_helper'

describe 'Groups (JavaScript fixtures)', type: :controller do
  include JavaScriptFixturesHelpers

  let(:admin) { create(:admin) }
  let(:group) { create(:group, name: 'frontend-fixtures-group', runners_token: 'runnerstoken:intabulasreferre')}

  render_views

  before(:all) do
    clean_frontend_fixtures('groups/')
  end

  before do
    group.add_maintainer(admin)
    sign_in(admin)
  end

  describe GroupsController, '(JavaScript fixtures)', type: :controller do
    it 'groups/edit.html' do
      get :edit, params: { id: group }

      expect(response).to be_successful
    end
  end

  describe Groups::Settings::CiCdController, '(JavaScript fixtures)', type: :controller do
    it 'groups/ci_cd_settings.html' do
      get :show, params: { group_id: group }

      expect(response).to be_successful
    end
  end
end
