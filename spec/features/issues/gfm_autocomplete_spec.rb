require 'rails_helper'

feature 'GFM autocomplete', feature: true, js: true do
  include WaitForAjax
  let(:user)    { create(:user) }
  let(:project) { create(:project) }
  let(:issue)   { create(:issue, project: project) }

  before do
    project.team << [user, :master]
    login_as(user)
    visit namespace_project_issue_path(project.namespace, project, issue)

    wait_for_ajax
  end

  it 'opens autocomplete menu when field starts with text' do
    page.within '.timeline-content-form' do
      find('#note_note').native.send_keys('')
      find('#note_note').native.send_keys('@')
    end

    expect(page).to have_selector('.atwho-view')
  end

  it 'opens autocomplete menu when field is prefixed with non-text character' do
    page.within '.timeline-content-form' do
      find('#note_note').native.send_keys('')
      find('#note_note').native.send_keys('@')
    end

    expect(page).to have_selector('.atwho-view')
  end

  it 'doesnt open autocomplete menu character is prefixed with text' do
    page.within '.timeline-content-form' do
      find('#note_note').native.send_keys('testing')
      find('#note_note').native.send_keys('@')
    end

    expect(page).not_to have_selector('.atwho-view')
  end
end
