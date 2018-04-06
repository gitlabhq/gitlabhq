require 'spec_helper'

describe 'Projects > Files > User wants to add a .gitignore file' do
  before do
    user = create(:user)
    project = create(:project, :repository)
    project.add_master(user)
    sign_in user
    visit project_new_blob_path(project, 'master', file_name: '.gitignore')
  end

  it 'user can see .gitignore dropdown' do
    expect(page).to have_css('.gitignore-selector')
  end

  it 'user can pick a .gitignore file from the dropdown', :js do
    find('.js-gitignore-selector').click
    wait_for_requests
    within '.gitignore-selector' do
      find('.dropdown-input-field').set('rails')
      find('.dropdown-content li', text: 'Rails').click
    end
    wait_for_requests

    expect(page).to have_css('.gitignore-selector .dropdown-toggle-text', text: 'Rails')
    expect(page).to have_content('/.bundle')
    expect(page).to have_content('# Gemfile.lock, .ruby-version, .ruby-gemset')
  end
end
