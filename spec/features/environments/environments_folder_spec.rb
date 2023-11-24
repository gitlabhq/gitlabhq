# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Environments Folder page', :js, feature_category: :environment_management do
  let(:folder_name) { 'folder' }

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let!(:envs) { create_list(:environment, 4, :with_folders, project: project, folder: folder_name) }

  before_all do
    project.add_role(user, :developer)
  end

  before do
    create(:environment, :production, project: project)
  end

  describe 'new folders page' do
    before do
      sign_in(user)
      visit folder_project_environments_path(project, folder_name)
      wait_for_requests
    end

    it 'renders the header with a folder name' do
      expect(page).to have_content("Environments / #{folder_name}")
    end
  end

  describe 'legacy folders page' do
    before do
      stub_feature_flags(environments_folder_new_look: false)
      sign_in(user)
      visit folder_project_environments_path(project, folder_name)
      wait_for_requests
    end

    it 'user opens folder view' do
      expect(page).to have_content("Environments / #{folder_name}")
      expect(page).not_to have_content('production')
      envs.each { |env| expect(page).to have_content(env.name.split('/').last) }
    end
  end
end
