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

  describe 'merge-request-only commands' do
    before do
      project.team << [user, :master]
      login_with(user)
      visit namespace_project_merge_request_path(project.namespace, project, merge_request)
    end

    after do
      wait_for_ajax
    end

    describe 'toggling the WIP prefix in the title from note' do
      context 'when the current user can toggle the WIP prefix' do
        it 'adds the WIP: prefix to the title' do
          write_note("/wip")

          expect(page).not_to have_content '/wip'
          expect(page).to have_content 'Your commands have been executed!'

          expect(merge_request.reload.work_in_progress?).to eq true
        end

        it 'removes the WIP: prefix from the title' do
          merge_request.title = merge_request.wip_title
          merge_request.save
          write_note("/wip")

          expect(page).not_to have_content '/wip'
          expect(page).to have_content 'Your commands have been executed!'

          expect(merge_request.reload.work_in_progress?).to eq false
        end
      end

      context 'when the current user cannot toggle the WIP prefix' do
        let(:guest) { create(:user) }
        before do
          project.team << [guest, :guest]
          logout
          login_with(guest)
          visit namespace_project_merge_request_path(project.namespace, project, merge_request)
        end

        it 'does not change the WIP prefix' do
          write_note("/wip")

          expect(page).not_to have_content '/wip'
          expect(page).not_to have_content 'Your commands have been executed!'

          expect(merge_request.reload.work_in_progress?).to eq false
        end
      end
    end

    describe 'adding a due date from note' do
      it 'does not recognize the command nor create a note' do
        write_note('/due 2016-08-28')

        expect(page).not_to have_content '/due 2016-08-28'
      end
    end
  end
end
