require 'rails_helper'

feature 'Merge Requests > User uses slash commands', feature: true, js: true do
  include WaitForAjax

  let(:user) { create(:user) }
  let(:project) { create(:project, :public) }
  let(:merge_request) { create(:merge_request, source_project: project) }
  let!(:milestone) { create(:milestone, project: project, title: 'ASAP') }

  it_behaves_like 'issuable record that supports slash commands in its description and notes', :merge_request do
    let(:issuable) { create(:merge_request, source_project: project) }
    let(:new_url_opts) { { merge_request: { source_branch: 'feature' } } }
  end

  describe 'adding a due date from note' do
    before do
      project.team << [user, :master]
      login_with(user)
      visit namespace_project_merge_request_path(project.namespace, project, merge_request)
    end

    it 'does not recognize the command nor create a note' do
      page.within('.js-main-target-form') do
        fill_in 'note[note]', with: "/due_date 2016-08-28"
        click_button 'Comment'
      end

      expect(page).not_to have_content '/due_date 2016-08-28'
    end
  end

  # Postponed because of high complexity
  xdescribe 'merging from note' do
    before do
      project.team << [user, :master]
      login_with(user)
      visit namespace_project_merge_request_path(project.namespace, project, merge_request)
    end

    it 'creates a note without the commands and interpret the commands accordingly' do
      page.within('.js-main-target-form') do
        fill_in 'note[note]', with: "Let's merge this!\n/merge\n/milestone %ASAP"
        click_button 'Comment'
      end

      expect(page).to have_content("Let's merge this!")
      expect(page).not_to have_content('/merge')
      expect(page).not_to have_content('/milestone %ASAP')

      merge_request.reload
      note = merge_request.notes.user.first

      expect(note.note).to eq "Let's merge this!\r\n"
      expect(merge_request).to be_merged
      expect(merge_request.milestone).to eq milestone
    end
  end
end
