require 'spec_helper'

feature 'User wants to add a .gitignore file', feature: true do
  include WaitForAjax

  before do
    user = create(:user)
    project = create(:project)
    project.team << [user, :master]
    login_as user
    visit namespace_project_new_blob_path(project.namespace, project, 'master', file_name: '.gitignore')
  end

  scenario 'user can see .gitignore dropdown' do
    expect(page).to have_css('.gitignore-selector')
  end

  scenario 'user can pick a .gitignore file from the dropdown', js: true do
    find('.js-gitignore-selector').click
    wait_for_ajax
    within '.gitignore-selector' do
      find('.dropdown-input-field').set('rails')
      find('.dropdown-content li', text: 'Rails').click
    end
    wait_for_ajax

    expect(page).to have_css('.gitignore-selector .dropdown-toggle-text', text: 'Rails')
    expect(page).to have_content('/.bundle')
    expect(page).to have_content('# Gemfile.lock, .ruby-version, .ruby-gemset')
  end
end
