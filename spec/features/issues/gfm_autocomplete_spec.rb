require 'rails_helper'

feature 'GFM autocomplete', feature: true, js: true do
  let(:user)    { create(:user) }
  let(:project) { create(:project) }
  let(:issue)   { create(:issue, project: project) }

  before do
    project.team << [user, :master]
    login_as(user)
    visit namespace_project_issue_path(project.namespace, project, issue)
  end

  it 'opens autocomplete menu when doesnt starts with space' do
    sleep 2

    page.within '.timeline-content-form' do
      find('#note_note').native.send_keys('testing')
      find('#note_note').native.send_keys('@')
    end

    expect(page).to have_selector('.atwho-view')
  end
end
