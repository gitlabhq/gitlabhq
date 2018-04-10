require 'spec_helper'

feature 'User visits the notifications tab', :js do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    project.add_master(user)
    sign_in(user)
    visit(profile_notifications_path)
  end

  it 'changes the project notifications setting' do
    expect(page).to have_content('Notifications')

    first('#notifications-button').click
    click_link('On mention')

    expect(page).to have_selector('#notifications-button', text: 'On mention')
  end
end
