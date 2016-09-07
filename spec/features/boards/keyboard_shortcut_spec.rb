require 'rails_helper'

describe 'Issue Boards shortcut', feature: true, js: true do
  let(:project) { create(:empty_project) }

  before do
    project.create_board
    project.board.lists.create(list_type: :backlog)
    project.board.lists.create(list_type: :done)

    login_as :admin

    visit namespace_project_path(project.namespace, project)
  end

  it 'takes user to issue board index' do
    find('body').native.send_keys('gl')
    expect(page).to have_selector('.boards-list')
  end
end
