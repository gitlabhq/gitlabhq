# frozen_string_literal: true

require 'spec_helper'

describe 'Projects > Files > Project owner sees a link to create a license file in empty project', :js do
  let(:project) { create(:project_empty_repo) }
  let(:project_maintainer) { project.owner }

  before do
    sign_in(project_maintainer)
  end

  it 'project maintainer creates a license file from a template' do
    visit project_path(project)
    click_on 'Add LICENSE'
    expect(page).to have_content('New file')

    expect(current_path).to eq(
      project_new_blob_path(project, 'master'))
    expect(find('#file_name').value).to eq('LICENSE')
    expect(page).to have_selector('.license-selector')

    select_template('MIT License')

    file_content = first('.file-editor')
    expect(file_content).to have_content('MIT License')
    expect(file_content).to have_content("Copyright (c) #{Time.now.year} #{project.namespace.human_name}")

    fill_in :commit_message, with: 'Add a LICENSE file', visible: true
    click_button 'Commit changes'

    expect(current_path).to eq(
      project_blob_path(project, 'master/LICENSE'))
    expect(page).to have_content('MIT License')
    expect(page).to have_content("Copyright (c) #{Time.now.year} #{project.namespace.human_name}")
  end

  def select_template(template)
    page.within('.js-license-selector-wrap') do
      click_button 'Apply a template'
      click_link template
      wait_for_requests
    end
  end
end
