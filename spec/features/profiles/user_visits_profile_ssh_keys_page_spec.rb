# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User visits the profile SSH keys page', feature_category: :user_profile do
  let(:user) { create(:user) }

  before do
    sign_in(user)

    visit(profile_keys_path)
  end

  it 'shows correct menu item' do
    expect(page).to have_active_navigation('SSH Keys')
  end
end
