require 'rails_helper'

describe 'Issue Boards shortcut', feature: true, js: true do
  let(:project) { create(:empty_project) }

  before do
    create(:board, project: project)

    gitlab_sign_in :admin

    visit project_path(project)
  end

  it 'takes user to issue board index' do
    find('body').native.send_keys('gb')
    expect(page).to have_selector('.boards-list')

    wait_for_requests
  end
end
