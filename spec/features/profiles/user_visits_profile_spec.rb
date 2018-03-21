require 'spec_helper'

describe 'User visits their profile' do
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  it 'shows correct menu item' do
    visit(profile_path)

    expect(page).to have_active_navigation('Profile')
  end

  it 'shows profile info' do
    visit(profile_path)

    expect(page).to have_content "This information will appear on your profile"
  end

  context 'when user has groups' do
    let(:group) do
      create :group do |group|
        group.add_owner(user)
      end
    end

    let!(:project) do
      create(:project, :repository, namespace: group) do |project|
        create(:closed_issue_event, project: project)
        project.add_master(user)
      end
    end

    def click_on_profile_picture
      find(:css, '.header-user-dropdown-toggle').click

      page.within ".header-user" do
        click_link "Profile"
      end
    end

    it 'shows user groups', :js do
      visit(profile_path)
      click_on_profile_picture

      page.within ".cover-block" do
        expect(page).to have_content user.name
        expect(page).to have_content user.username
      end

      page.within ".content" do
        click_link "Groups"
      end

      page.within "#groups" do
        expect(page).to have_content group.name
      end
    end
  end
end
