require 'spec_helper'

feature 'Find file keyboard shortcuts', feature: true, js: true do
  let(:user) { create(:user) }
  let(:project) { create(:project) }

  before do
    project.team << [user, :master]
    sign_in user

    visit project_find_file_path(project, project.repository.root_ref)

    wait_for_requests
  end

  it 'opens file when pressing enter key' do
    fill_in 'file_find', with: 'CHANGELOG'

    find('#file_find').native.send_keys(:enter)

    expect(page).to have_selector('.blob-content-holder')

    page.within('.js-file-title') do
      expect(page).to have_content('CHANGELOG')
    end
  end

  it 'navigates files with arrow keys' do
    fill_in 'file_find', with: 'application.'

    find('#file_find').native.send_keys(:down)
    find('#file_find').native.send_keys(:enter)

    expect(page).to have_selector('.blob-content-holder')

    page.within('.js-file-title') do
      expect(page).to have_content('application.js')
    end
  end
end
