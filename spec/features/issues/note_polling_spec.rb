require 'spec_helper'

feature 'Issue notes polling', :feature, :js do
  let(:project) { create(:empty_project, :public) }
  let(:issue) { create(:issue, project: project) }

  before do
    visit namespace_project_issue_path(project.namespace, project, issue)
  end

  it 'should display the new comment' do
    note = create(:note, noteable: issue, project: project, note: 'Looks good!')
    page.execute_script('notes.refresh();')

    expect(page).to have_selector("#note_#{note.id}", text: 'Looks good!')
  end
end
