# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User searches their settings', :js, feature_category: :user_profile do
  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)
    stub_feature_flags(edit_user_profile_vue: false)
  end

  context 'in profile page' do
    before do
      visit user_settings_profile_path
    end

    it_behaves_like 'can search settings', 'Public avatar', 'Main settings'
  end

  context 'in preferences page' do
    before do
      visit profile_preferences_path
    end

    it_behaves_like 'can search settings', 'Syntax highlighting theme', 'Behavior'
  end
end
