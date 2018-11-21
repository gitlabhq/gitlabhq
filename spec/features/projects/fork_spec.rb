require 'spec_helper'

describe 'Project fork' do
  include ProjectForksHelper

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

  it 'forks the project' do
    visit project_path(project)

    click_link 'Fork'

    page.within '.fork-thumbnail-container' do
      click_link user.name
    end

    expect(page).to have_content 'Forked from'

    visit project_path(project)

    expect(page).to have_content(/new merge request/i)

    page.within '.nav-sidebar' do
      first(:link, 'Merge Requests').click
    end

    expect(page).to have_content(/new merge request/i)

    page.within '#content-body' do
      click_link('New merge request')
    end

    expect(current_path).to have_content(/#{user.namespace.path}/i)
  end

  it 'shows avatars when Gravatar is disabled' do
    stub_application_setting(gravatar_enabled: false)

    visit project_path(project)

    click_link 'Fork'

    page.within('.fork-thumbnail-container') do
      expect(page).to have_css('div.identicon')
    end
  end

  it 'shows the forked project on the list' do
    visit project_path(project)

    click_link 'Fork'

    page.within '.fork-thumbnail-container' do
      click_link user.name
    end

    visit project_forks_path(project)

    forked_project = user.fork_of(project.reload)

    page.within('.js-projects-list-holder') do
      expect(page).to have_content("#{forked_project.namespace.human_name} / #{forked_project.name}")
    end

    forked_project.update!(path: 'test-crappy-path')

    visit project_forks_path(project)

    page.within('.js-projects-list-holder') do
      expect(page).to have_content("#{forked_project.namespace.human_name} / #{forked_project.name}")
    end
  end

  context 'when the project is private' do
    let(:project) { create(:project, :repository) }
    let(:another_user) { create(:user, name: 'Mike') }

    before do
      project.add_reporter(user)
      project.add_reporter(another_user)
    end

    it 'renders private forks of the project' do
      visit project_path(project)

      another_project_fork = Projects::ForkService.new(project, another_user).execute

      click_link 'Fork'

      page.within '.fork-thumbnail-container' do
        click_link user.name
      end

      visit project_forks_path(project)

      page.within('.js-projects-list-holder') do
        user_project_fork = user.fork_of(project.reload)
        expect(page).to have_content("#{user_project_fork.namespace.human_name} / #{user_project_fork.name}")
      end

      expect(page).not_to have_content("#{another_project_fork.namespace.human_name} / #{another_project_fork.name}")
      expect(page).to have_content("1 private fork")
    end
  end

  context 'when the user already forked the project' do
    before do
      create(:project, :repository, name: project.name, namespace: user.namespace)
    end

    it 'renders error' do
      visit project_path(project)

      click_link 'Fork'

      page.within '.fork-thumbnail-container' do
        click_link user.name
      end

      expect(page).to have_content "Name has already been taken"
    end
  end

  context 'maintainer in group' do
    let(:group) { create(:group) }

    before do
      group.add_maintainer(user)
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

    it 'links to the fork if the project was already forked within that namespace' do
      forked_project = fork_project(project, user, namespace: group, repository: true)

      visit new_project_fork_path(project)

      expect(page).to have_css('div.forked', text: group.full_name)

      click_link group.full_name

      expect(current_path).to eq(project_path(forked_project))
    end
  end
end
