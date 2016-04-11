require 'spec_helper'

feature 'creates a license file in empty project', feature: true, js: true do
  include Select2Helper

  let(:project_master) { create(:user) }
  let(:project) { create(:project_empty_repo) }
  background do
    project.team << [project_master, :master]
    login_as(project_master)
    visit namespace_project_path(project.namespace, project)
  end

  scenario 'project master creates a license file from a template' do
    click_on 'LICENSE'

    expect(current_path).to eq(
      namespace_project_new_blob_path(project.namespace, project, 'master'))
    expect(find('#file_name').value).to eq('LICENSE')
    expect(page).to have_selector('.license-selector')

    select2('mit', from: '#license_type')

    file_content = find('.file-content')
    expect(file_content).to have_content('The MIT License (MIT)')
    expect(file_content).to have_content("Copyright (c) 2016 #{project.namespace.human_name}")

    fill_in :commit_message, with: 'Add a LICENSE file', visible: true
    click_button 'Commit Changes'

    expect(current_path).to eq(
      namespace_project_blob_path(project.namespace, project, 'master/LICENSE'))
    expect(page).to have_content('The MIT License (MIT)')
    expect(page).to have_content("Copyright (c) 2016 #{project.namespace.human_name}")
  end
end
