# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::UsersController, '(JavaScript fixtures)', type: :controller do
  include StubENV
  include JavaScriptFixturesHelpers
  include AdminModeHelper

  let(:admin) { create(:admin) }

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
    sign_in(admin)
    enable_admin_mode!(admin)
  end

  render_views

  it 'admin/users/new_with_internal_user_regex.html' do
    stub_application_setting(user_default_external: true)
    stub_application_setting(user_default_internal_regex: '^(?:(?!\.ext@).)*$\r?')

    get :new

    expect(response).to be_successful
  end
end
