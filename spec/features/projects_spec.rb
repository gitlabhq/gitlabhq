require 'spec_helper'

feature 'Project' do
  include ProjectForksHelper

  describe 'creating from template' do
    let(:user)    { create(:user) }
    let(:template) { Gitlab::ProjectTemplate.find(:rails) }

    before do
      sign_in user
      visit new_project_path
    end

    it "allows creation from templates" do
      page.choose(template.name)
      fill_in("project_path", with: template.name)

      page.within '#content-body' do
        click_button "Create project"
      end

      expect(page).to have_content template.name
    end
  end

  describe 'description' do
    let(:project) { create(:project, :repository) }
    let(:path)    { project_path(project) }

    before do
      sign_in(create(:admin))
    end

    it 'parses Markdown' do
      project.update_attribute(:description, 'This is **my** project')
      visit path
      expect(page).to have_css('.project-home-desc > p > strong')
    end

    it 'passes through html-pipeline' do
      project.update_attribute(:description, 'This project is the :poop:')
      visit path
      expect(page).to have_css('.project-home-desc > p > gl-emoji')
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
    let(:project) { fork_project(create(:project, :public), user, namespace_id: user.namespace) }

    before do
      sign_in user
      visit edit_project_path(project)
    end

    it 'removes fork' do
      expect(page).to have_content 'Remove fork relationship'

      remove_with_confirm('Remove fork relationship', project.path)

      expect(page).to have_content 'The fork relationship has been removed.'
      expect(project.reload.forked?).to be_falsey
      expect(page).not_to have_content 'Remove fork relationship'
    end
  end

  describe 'removal', js: true do
    let(:user)    { create(:user, username: 'test', name: 'test') }
    let(:project) { create(:project, namespace: user.namespace, name: 'project1') }

    before do
      sign_in(user)
      project.team << [user, :master]
      visit edit_project_path(project)
    end

    it 'removes a project' do
      expect { remove_with_confirm('Remove project', project.path) }.to change {Project.count}.by(-1)
      expect(page).to have_content "Project 'test / project1' will be deleted."
      expect(Project.all.count).to be_zero
      expect(project.issues).to be_empty
      expect(project.merge_requests).to be_empty
    end
  end

  describe 'tree view (default view is set to Files)' do
    let(:user) { create(:user, project_view: 'files') }
    let(:project) { create(:forked_project_with_submodules) }

    before do
      project.team << [user, :master]
      sign_in user
      visit project_path(project)
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

  describe 'activity view' do
    let(:user) { create(:user, project_view: 'activity') }
    let(:project) { create(:project, :repository) }

    before do
      project.team << [user, :master]
      sign_in user
      visit project_path(project)
    end

    it 'loads activity', :js do
      expect(page).to have_selector('.event-item')
    end
  end

  def remove_with_confirm(button_text, confirm_with)
    click_button button_text
    fill_in 'confirm_name_input', with: confirm_with
    click_button 'Confirm'
  end
end
