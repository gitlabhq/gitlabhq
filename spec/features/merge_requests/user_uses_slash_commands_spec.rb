require 'rails_helper'

feature 'Merge Requests > User uses slash commands', feature: true, js: true do
  include SlashCommandsHelpers
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

    after do
      wait_for_ajax
    end

    it 'does not recognize the command nor create a note' do
      write_note("/due 2016-08-28")

      expect(page).not_to have_content '/due 2016-08-28'
    end
  end
end
