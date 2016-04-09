require 'spec_helper'

feature 'Member autocomplete', feature: true do
  let(:project) { create(:project, :public) }
  let(:user) { create(:user) }
  let(:participant) { create(:user) }
  let(:author) { create(:user) }
  let(:issue) { create(:issue, author: author, project: project) }

  before do
    login_as user
  end

  describe 'On a Issue', js: true do
    before do
      create(:note, note: 'ultralight beam', noteable: issue, author: participant)
      visit_issue(project, issue)
    end

    describe 'adding a new note' do
      describe 'when typing @' do

        before do
          sleep 1
          page.within('.new-note') do
            sleep 1
            find('#note_note').native.send_keys('@')
          end
        end

        it 'suggestions are displayed' do
          expect(page).to have_selector('.atwho-view', visible: true)
        end

        it 'author is a suggestion' do
          page.within('.atwho-view', visible: true) do
            expect(page).to have_content(author.username)
          end
        end

        it 'participant is a suggestion' do
          page.within('.atwho-view', visible: true) do
            expect(page).to have_content(participant.username)
          end
        end
      end
    end
  end

  def visit_issue(project, issue)
    visit namespace_project_issue_path(project.namespace, project, issue)
  end
end
