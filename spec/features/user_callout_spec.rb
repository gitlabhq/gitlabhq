require 'spec_helper'

describe 'User Callouts', js: true do
  let(:user) { create(:user) }
  let(:project) { create(:empty_project, path: 'gitlab', name: 'sample') }

  before do
    login_as(user)
    project.team << [user, :master]    
  end

  it 'takes you to the profile preferences when the link is clicked' do    
    visit dashboard_projects_path
    click_link 'Check it out'
    expect(current_path).to eq profile_preferences_path
  end

  describe 'user callout should appear in two routes' do
    it 'shows up on the user profile' do
      visit user_path(user)
      expect(find('#user-callout')).to have_content 'Customize your experience'
    end

    it 'shows up on the dashboard projects' do
      visit dashboard_projects_path
      expect(find('#user-callout')).to have_content 'Customize your experience'
    end
  end

  it 'hides the user callout when click on the dismiss icon' do
    visit user_path(user)
    within('#user-callout') do
      find('.dismiss-icon').click
    end
    expect(page).not_to have_selector('#user-callout')
  end
end
