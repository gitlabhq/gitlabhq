# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User visits the notifications tab', :js do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    project.add_maintainer(user)
    sign_in(user)
    visit(profile_notifications_path)
  end

  it 'turns on the receive product marketing emails setting' do
    expect(page).to have_content('Notifications')

    expect do
      check 'Receive product marketing emails'
    end.to change { user.reload.email_opted_in }.to(true)
  end

  it 'changes the project notifications setting' do
    expect(page).to have_content('Notifications')

    first('[data-testid="notification-dropdown"]').click
    click_button('On mention')

    expect(page).to have_selector('[data-testid="notification-dropdown"]', text: 'On mention')
  end

  context 'when project emails are disabled' do
    let(:project) { create(:project, emails_disabled: true) }

    it 'notification button is disabled' do
      expect(page).to have_selector('[data-testid="notification-dropdown"] .disabled')
    end
  end
end
