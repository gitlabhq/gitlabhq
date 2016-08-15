require 'spec_helper'

feature 'project owner sees a link to create a license file in empty project', feature: true, js: true do
  include WaitForAjax

  let(:project_master) { create(:user) }
  let(:project) { create(:empty_project) }
  background do
    project.team << [project_master, :master]
    login_as(project_master)
  end

  scenario 'project master creates a license file from a template' do
    visit namespace_project_path(project.namespace, project)
    click_link 'Create empty bare repository'
    click_on 'LICENSE'
    expect(page).to have_content('New File')

    expect(current_path).to eq(
      namespace_project_new_blob_path(project.namespace, project, 'master'))
    expect(find('#file_name').value).to eq('LICENSE')
    expect(page).to have_selector('.license-selector')

    select_template('MIT License')

    file_content = find('.file-content')
    expect(file_content).to have_content('The MIT License (MIT)')
    expect(file_content).to have_content("Copyright (c) #{Time.now.year} #{project.namespace.human_name}")

    fill_in :commit_message, with: 'Add a LICENSE file', visible: true
    # Remove pre-receive hook so we can push without auth
    FileUtils.rm_f(File.join(project.repository.path, 'hooks', 'pre-receive'))
    click_button 'Commit Changes'

    expect(current_path).to eq(
      namespace_project_blob_path(project.namespace, project, 'master/LICENSE'))
    expect(page).to have_content('The MIT License (MIT)')
    expect(page).to have_content("Copyright (c) #{Time.now.year} #{project.namespace.human_name}")
  end

  def select_template(template)
    page.within('.js-license-selector-wrap') do
      click_button 'Choose a License template'
      click_link template
      wait_for_ajax
    end
  end
end
