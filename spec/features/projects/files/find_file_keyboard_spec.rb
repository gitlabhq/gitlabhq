require 'spec_helper'

feature 'Find file keyboard shortcuts', feature: true, js: true do
  include WaitForAjax

  let(:user) { create(:user) }
  let(:project) { create(:project) }

  before do
    project.team << [user, :master]
    login_as user

    visit namespace_project_find_file_path(project.namespace, project, project.repository.root_ref)

    wait_for_ajax
  end

  it 'opens file when pressing enter key' do
    fill_in 'file_find', with: 'CHANGELOG'

    find('#file_find').native.send_keys(:enter)

    expect(page).to have_selector('.blob-content-holder')

    page.within('.file-title') do
      expect(page).to have_content('CHANGELOG')
    end
  end

  it 'navigates files with arrow keys' do
    fill_in 'file_find', with: 'application.'

    find('#file_find').native.send_keys(:down)
    find('#file_find').native.send_keys(:enter)

    expect(page).to have_selector('.blob-content-holder')

    page.within('.file-title') do
      expect(page).to have_content('application.js')
    end
  end
end
