require 'spec_helper'

describe "Admin::Projects"  do
  include Select2Helper

  let(:user) { create :user }
  let!(:project) { create(:project) }
  let!(:current_user) { create(:admin) }

  before do
    sign_in(current_user)
  end

  describe "GET /admin/projects" do
    let!(:archived_project) { create :project, :public, :archived }

    before do
      visit admin_projects_path
    end

    it "is ok" do
      expect(current_path).to eq(admin_projects_path)
    end

    it 'renders projects list without archived project' do
      expect(page).to have_content(project.name)
      expect(page).not_to have_content(archived_project.name)
    end

    it 'renders all projects', js: true do
      find(:css, '#sort-projects-dropdown').click
      click_link 'Show archived projects'

      expect(page).to have_content(project.name)
      expect(page).to have_content(archived_project.name)
      expect(page).to have_xpath("//span[@class='label label-warning']", text: 'archived')
    end
  end

  describe "GET /admin/projects/:namespace_id/:id" do
    before do
      visit admin_projects_path
      click_link "#{project.name}"
    end

    it do
      expect(current_path).to eq admin_project_path(project)
    end

    it "has project info" do
      expect(page).to have_content(project.path)
      expect(page).to have_content(project.name)
      expect(page).to have_content(project.name_with_namespace)
      expect(page).to have_content(project.creator.name)
    end
  end

  describe 'transfer project' do
    before do
      create(:group, name: 'Web')

      allow_any_instance_of(Projects::TransferService)
        .to receive(:move_uploads_to_new_namespace).and_return(true)
    end

    it 'transfers project to group web', js: true do
      visit admin_project_path(project)

      click_button 'Search for Namespace'
      click_link 'group: web'
      click_button 'Transfer'

      expect(page).to have_content("Web / #{project.name}")
      expect(page).to have_content('Namespace: Web')
    end
  end

  describe 'add admin himself to a project' do
    before do
      project.team << [user, :master]
    end

    it 'adds admin a to a project as developer', js: true do
      visit project_project_members_path(project)

      page.within '.users-project-form' do
        select2(current_user.id, from: '#user_ids', multiple: true)
        select 'Developer', from: 'access_level'
      end

      click_button 'Add to project'

      page.within '.content-list' do
        expect(page).to have_content(current_user.name)
        expect(page).to have_content('Developer')
      end
    end
  end

  describe 'admin remove himself from a project' do
    before do
      project.team << [user, :master]
      project.team << [current_user, :developer]
    end

    it 'removes admin from the project' do
      visit project_project_members_path(project)

      page.within '.content-list' do
        expect(page).to have_content(current_user.name)
        expect(page).to have_content('Developer')
      end

      find(:css, '.content-list li', text: current_user.name).find(:css, 'a.btn-remove').click

      expect(page).not_to have_selector(:css, '.content-list')
    end
  end
end
