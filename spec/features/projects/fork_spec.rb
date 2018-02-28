require 'spec_helper'

describe 'Project fork' do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public, :repository) }

  before do
    sign_in user
  end

  it 'allows user to fork project' do
    visit project_path(project)

    expect(page).not_to have_css('a.disabled', text: 'Fork')
  end

  it 'disables fork button when user has exceeded project limit' do
    user.projects_limit = 0
    user.save!

    visit project_path(project)

    expect(page).to have_css('a.disabled', text: 'Fork')
  end

  context 'master in group' do
    before do
      group = create(:group)
      group.add_master(user)
    end

    it 'allows user to fork project to group or to user namespace' do
      visit project_path(project)

      expect(page).not_to have_css('a.disabled', text: 'Fork')

      click_link 'Fork'

      expect(page).to have_css('.fork-thumbnail', count: 2)
      expect(page).not_to have_css('.fork-thumbnail.disabled')
    end

    it 'allows user to fork project to group and not user when exceeded project limit' do
      user.projects_limit = 0
      user.save!

      visit project_path(project)

      expect(page).not_to have_css('a.disabled', text: 'Fork')

      click_link 'Fork'

      expect(page).to have_css('.fork-thumbnail', count: 2)
      expect(page).to have_css('.fork-thumbnail.disabled')
    end
  end
end
