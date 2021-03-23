# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User views pipeline editor button on root ci config file', :js do
  include BlobSpecHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public, :repository) }

  context "when the ci config is the root file" do
    before do
      project.add_developer(user)
      sign_in(user)
    end

    it 'shows the button to the Pipeline Editor' do
      project.update!(ci_config_path: '.my-config.yml')
      project.repository.create_file(user, project.ci_config_path_or_default, 'test', message: 'testing', branch_name: 'master')
      visit project_blob_path(project, File.join('master', '.my-config.yml'))

      expect(page).to have_content('Pipeline Editor')
    end

    it 'does not shows the Pipeline Editor button' do
      project.repository.create_file(user, '.my-sub-config.yml', 'test', message: 'testing', branch_name: 'master')
      visit project_blob_path(project, File.join('master', '.my-sub-config.yml'))

      expect(page).not_to have_content('Pipeline Editor')
    end
  end

  context "when user cannot collaborate" do
    before do
      sign_in(user)
    end
    it 'does not shows the Pipeline Editor button' do
      visit project_blob_path(project, File.join('master', '.my-config.yml'))
      expect(page).not_to have_content('Pipeline Editor')
    end
  end
end
