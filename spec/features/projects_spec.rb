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

  describe 'removal', js: true do
    let(:user)    { create(:user) }
    let(:project) { create(:project, namespace: user.namespace) }

    before do
      login_with(user)
      project.team << [user, :master]
      visit edit_namespace_project_path(project.namespace, project)
    end

    it 'should remove project' do
      expect { remove_project }.to change {Project.count}.by(-1)
    end
  end

  def remove_project
    click_button "Remove project"
    fill_in 'confirm_name_input', with: project.path
    click_button 'Confirm'
  end
end
