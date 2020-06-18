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

  it 'changes the project notifications setting' do
    expect(page).to have_content('Notifications')

    first('#notifications-button').click
    click_link('On mention')

    expect(page).to have_selector('#notifications-button', text: 'On mention')
  end

  context 'when project emails are disabled' do
    let(:project) { create(:project, emails_disabled: true) }

    it 'notification button is disabled' do
      expect(page).to have_selector('.notifications-btn.disabled', visible: true)
    end
  end
end
