# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Groups (JavaScript fixtures)', type: :controller do
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
end
