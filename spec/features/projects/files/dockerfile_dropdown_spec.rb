require 'spec_helper'

feature 'User wants to add a Dockerfile file', feature: true do
  include WaitForAjax

  before do
    user = create(:user)
    project = create(:project)
    project.team << [user, :master]
    login_as user
    visit namespace_project_new_blob_path(project.namespace, project, 'master', file_name: 'Dockerfile')
  end

  scenario 'user can see Dockerfile dropdown' do
    expect(page).to have_css('.dockerfile-selector')
  end

  scenario 'user can pick a Dockerfile file from the dropdown', js: true do
    find('.js-dockerfile-selector').click
    wait_for_ajax
    within '.dockerfile-selector' do
      find('.dropdown-input-field').set('HTTPd')
      find('.dropdown-content li', text: 'HTTPd').click
    end
    wait_for_ajax

    expect(page).to have_css('.dockerfile-selector .dropdown-toggle-text', text: 'HTTPd')
    expect(page).to have_content('COPY ./ /usr/local/apache2/htdocs/')
  end
end
