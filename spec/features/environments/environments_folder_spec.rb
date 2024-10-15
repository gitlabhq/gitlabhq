# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Environments Folder page', :js, feature_category: :environment_management do
  let(:folder_name) { 'folder' }

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let!(:envs) { create_list(:environment, 4, :with_folders, project: project, folder: folder_name) }
  let!(:stopped_env) { create(:environment, :stopped, :with_folders, project: project, folder: folder_name) }

  def get_env_name(environment)
    environment.name.split('/').last
  end

  def find_env_element(environment)
    find_by_id(environment.name)
  end

  def stop_environment(environment)
    environment_item = find_env_element(environment)
    within(environment_item) do
      click_button 'Stop'
    end

    within('.modal') do
      click_button 'Stop environment'
    end

    wait_for_requests
  end

  def redeploy_environment(environment)
    environment_item = find_env_element(environment)
    within(environment_item) do
      click_button 'More actions'
      click_button 'Delete environment'
    end

    within('.modal') do
      click_button 'Delete environment'
    end

    wait_for_requests
  end

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

    it 'renders the environments' do
      expect(page).not_to have_content('production')
      envs.each { |env| expect(page).to have_content(get_env_name(env)) }
    end

    it 'shows scope tabs' do
      expect(page).to have_content("Active")
      expect(page).to have_content("Stopped")
    end

    it 'can stop the environment' do
      environment_to_stop = envs.first

      stop_environment(environment_to_stop)

      expect(page).not_to have_content(get_env_name(environment_to_stop))
    end

    describe 'stopped environments tab' do
      before do
        element = find('a', text: 'Stopped')
        element.click
        wait_for_requests
      end

      it 'shows stopped environments on stopped tab' do
        expect(page).to have_content(get_env_name(stopped_env))
      end

      it 'can re-start the environment' do
        redeploy_environment(stopped_env)

        expect(page).not_to have_content(get_env_name(stopped_env))
      end
    end

    describe 'pagination' do
      # rubocop:disable FactoryBot/ExcessiveCreateList -- need >20 items to test pagination
      let!(:envs) { create_list(:environment, 25, :with_folders, project: project, folder: folder_name) }

      # rubocop:enable FactoryBot/ExcessiveCreateList
      it 'shows pagination' do
        pagination = find('.gl-pagination')

        expect(pagination).to have_content('2')
      end

      it 'can navigate to the next page and updates the url' do
        pagination = find('.gl-pagination')
        pagination.scroll_to(:bottom)
        within(pagination) do
          click_link 'Next'
        end

        wait_for_requests

        expect(current_url).to include('page=2')
      end
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
      envs.each { |env| expect(page).to have_content(get_env_name(env)) }
    end
  end
end
