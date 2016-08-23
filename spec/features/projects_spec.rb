require 'spec_helper'

feature 'Project', feature: true do
  describe 'description' do
    let(:project) { create(:project) }
    let(:path)    { namespace_project_path(project.namespace, project) }

    before do
      login_as(:admin)
    end

    it 'parses Markdown' do
      project.update_attribute(:description, 'This is **my** project')
      visit path
      expect(page).to have_css('.project-home-desc > p > strong')
    end

    it 'passes through html-pipeline' do
      project.update_attribute(:description, 'This project is the :poop:')
      visit path
      expect(page).to have_css('.project-home-desc > p > img')
    end

    it 'sanitizes unwanted tags' do
      project.update_attribute(:description, "```\ncode\n```")
      visit path
      expect(page).not_to have_css('.project-home-desc code')
    end

    it 'permits `rel` attribute on links' do
      project.update_attribute(:description, 'https://google.com/')
      visit path
      expect(page).to have_css('.project-home-desc a[rel]')
    end
  end

  describe 'remove forked relationship', js: true do
    let(:user)    { create(:user) }
    let(:project) { create(:project, namespace: user.namespace) }

    before do
      login_with user
      create(:forked_project_link, forked_to_project: project)
      visit edit_namespace_project_path(project.namespace, project)
    end

    it 'removes fork' do
      expect(page).to have_content 'Remove fork relationship'

      remove_with_confirm('Remove fork relationship', project.path)

      expect(page).to have_content 'The fork relationship has been removed.'
      expect(project.forked?).to be_falsey
      expect(page).not_to have_content 'Remove fork relationship'
    end
  end

  describe 'removal', js: true do
    let(:user)    { create(:user) }
    let(:project) { create(:project, namespace: user.namespace) }

    before do
      login_with(user)
      project.team << [user, :master]
      visit edit_namespace_project_path(project.namespace, project)
    end

    it 'removes project' do
      expect { remove_with_confirm('Remove project', project.path) }.to change {Project.count}.by(-1)
    end
  end

  describe 'project title' do
    include WaitForAjax

    let(:user)    { create(:user) }
    let(:project) { create(:project, namespace: user.namespace) }

    before do
      login_with(user)
      project.team.add_user(user, Gitlab::Access::MASTER)
      visit namespace_project_path(project.namespace, project)
    end

    it 'clicks toggle and shows dropdown', js: true do
      find('.js-projects-dropdown-toggle').click
      expect(page).to have_css('.dropdown-menu-projects .dropdown-content li', count: 1)
    end
  end

  describe 'project title' do
    let(:user)    { create(:user) }
    let(:project) { create(:project, namespace: user.namespace) }
    let(:project2) { create(:project, namespace: user.namespace, path: 'test') }
    let(:issue) { create(:issue, project: project) }

    context 'on issues page', js: true do
      before do
        login_with(user)
        project.team.add_user(user, Gitlab::Access::MASTER)
        project2.team.add_user(user, Gitlab::Access::MASTER)
        visit namespace_project_issue_path(project.namespace, project, issue)
      end

      it 'clicks toggle and shows dropdown' do
        find('.js-projects-dropdown-toggle').click
        expect(page).to have_css('.dropdown-menu-projects .dropdown-content li', count: 2)

        page.within '.dropdown-menu-projects' do
          click_link project.name_with_namespace
        end

        expect(page).to have_content project.name
      end
    end
  end

  describe 'tree view (default view is set to Files)' do
    let(:user) { create(:user, project_view: 'files') }
    let(:project) { create(:forked_project_with_submodules) }

    before do
      project.team << [user, :master]
      login_as user
      visit namespace_project_path(project.namespace, project)
    end

    it 'has working links to files' do
      click_link('PROCESS.md')

      expect(page.status_code).to eq(200)
    end

    it 'has working links to directories' do
      click_link('encoding')

      expect(page.status_code).to eq(200)
    end

    it 'has working links to submodules' do
      click_link('645f6c4c')

      expect(page.status_code).to eq(200)
    end
  end

  def remove_with_confirm(button_text, confirm_with)
    click_button button_text
    fill_in 'confirm_name_input', with: confirm_with
    click_button 'Confirm'
  end
end
