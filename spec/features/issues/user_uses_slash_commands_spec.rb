require 'rails_helper'

feature 'Issues > User uses slash commands', feature: true, js: true do
  include SlashCommandsHelpers
  include WaitForAjax

  it_behaves_like 'issuable record that supports slash commands in its description and notes', :issue do
    let(:issuable) { create(:issue, project: project) }
  end

  describe 'issue-only commands' do
    let(:user) { create(:user) }
    let(:project) { create(:project, :public) }

    before do
      project.team << [user, :master]
      login_with(user)
      visit namespace_project_issue_path(project.namespace, project, issue)
    end

    after do
      wait_for_ajax
    end

    describe 'adding a due date from note' do
      let(:issue) { create(:issue, project: project) }

      it 'does not create a note, and sets the due date accordingly' do
        write_note("/due 2016-08-28")

        expect(page).not_to have_content '/due 2016-08-28'
        expect(page).to have_content 'Your commands have been executed!'

        issue.reload

        expect(issue.due_date).to eq Date.new(2016, 8, 28)
      end
    end

    describe 'removing a due date from note' do
      let(:issue) { create(:issue, project: project, due_date: Date.new(2016, 8, 28)) }

      it 'does not create a note, and removes the due date accordingly' do
        expect(issue.due_date).to eq Date.new(2016, 8, 28)

        write_note("/remove_due_date")

        expect(page).not_to have_content '/remove_due_date'
        expect(page).to have_content 'Your commands have been executed!'

        issue.reload

        expect(issue.due_date).to be_nil
      end
    end
  end
end
