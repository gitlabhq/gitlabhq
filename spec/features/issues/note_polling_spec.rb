require 'spec_helper'

feature 'Issue notes polling' do
  let!(:project) { create(:project, :public) }
  let!(:issue) { create(:issue, project: project) }

  background do
    visit namespace_project_issue_path(project.namespace, project, issue)
  end

  scenario 'Another user adds a comment to an issue', js: true do
    note = create(:note_on_issue, noteable: issue,
                  project_id: project.project_id,
                  note: 'Looks good!')
    sleep 16 # refresh interval in notes.js.coffee, 15 seconds
    expect(page).to have_selector("#note_#{note.id}", text: 'Looks good!')
  end
end
