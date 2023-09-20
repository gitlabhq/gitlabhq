# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User visits the notifications tab', :js, feature_category: :user_profile do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    project.add_maintainer(user)
    sign_in(user)
    visit(profile_notifications_path)
  end

  it 'changes the project notifications setting' do
    expect(page).to have_content('Notifications')

    first('[data-testid="notification-dropdown"]').click
    click_button('On mention')

    expect(page).to have_selector('[data-testid="notification-dropdown"]', text: 'On mention')
  end

  context 'when project emails are disabled' do
    let_it_be(:project) { create(:project, emails_enabled: false) }

    it 'notification button is disabled' do
      expect(page).to have_selector('[data-testid="notification-dropdown"] .disabled')
    end
  end
end
