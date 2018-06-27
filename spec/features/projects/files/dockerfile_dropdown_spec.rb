require 'spec_helper'

describe 'Projects > Files > User wants to add a Dockerfile file' do
  before do
    project = create(:project, :repository)
    sign_in project.owner
    visit project_new_blob_path(project, 'master', file_name: 'Dockerfile')
  end

  it 'user can pick a Dockerfile file from the dropdown', :js do
    expect(page).to have_css('.dockerfile-selector')

    find('.js-dockerfile-selector').click

    wait_for_requests

    within '.dockerfile-selector' do
      find('.dropdown-input-field').set('HTTPd')
      find('.dropdown-content li', text: 'HTTPd').click
    end

    wait_for_requests

    expect(page).to have_css('.dockerfile-selector .dropdown-toggle-text', text: 'HTTPd')
    expect(page).to have_content('COPY ./ /usr/local/apache2/htdocs/')
  end
end
