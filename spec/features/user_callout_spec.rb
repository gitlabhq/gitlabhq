require 'spec_helper'

describe 'User Callouts', js: true do
  let(:user) { create(:user) }
  let(:another_user) { create(:user) }
  let(:project) { create(:empty_project, path: 'gitlab', name: 'sample') }

  before do
    sign_in(user)
    project.team << [user, :master]
  end

  it 'takes you to the profile preferences when the link is clicked' do
    visit dashboard_projects_path
    click_link 'Check it out'
    expect(current_path).to eq profile_preferences_path
  end

  it 'does not show when cookie is set' do
    visit dashboard_projects_path

    within('.user-callout') do
      find('.close').trigger('click')
    end

    visit dashboard_projects_path

    expect(page).not_to have_selector('.user-callout')
  end

  describe 'user callout should appear in two routes' do
    it 'shows up on the user profile' do
      visit user_path(user)
      expect(find('.user-callout')).to have_content 'Customize your experience'
    end

    it 'shows up on the dashboard projects' do
      visit dashboard_projects_path
      expect(find('.user-callout')).to have_content 'Customize your experience'
    end
  end

  it 'hides the user callout when click on the dismiss icon' do
    visit user_path(user)
    within('.user-callout') do
      find('.close').click
    end
    expect(page).not_to have_selector('.user-callout')
  end

  it 'does not show callout on another users profile' do
    visit user_path(another_user)
    expect(page).not_to have_selector('.user-callout')
  end
end
