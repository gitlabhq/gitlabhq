# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User visits the profile account page', feature_category: :user_profile do
  let(:user) { create(:user) }

  before do
    sign_in(user)

    visit(profile_account_path)
  end

  it 'shows correct menu item' do
    expect(page).to have_active_navigation('Account')
  end
end
