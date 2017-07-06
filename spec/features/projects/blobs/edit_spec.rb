require 'spec_helper'

feature 'Editing file blob', feature: true, js: true do
  include TreeHelper

  let(:project) { create(:project, :public, :test_repo) }
  let(:merge_request) { create(:merge_request, source_project: project, source_branch: 'feature', target_branch: 'master') }
  let(:branch) { 'master' }
  let(:file_path) { project.repository.ls_files(project.repository.root_ref)[1] }

  context 'as a developer' do
    let(:user) { create(:user) }
    let(:role) { :developer }

    before do
      project.team << [user, role]
      sign_in(user)
    end

    def edit_and_commit
      wait_for_requests
      find('.js-edit-blob').click
      execute_script('ace.edit("editor").setValue("class NextFeature\nend\n")')
      click_button 'Commit changes'
    end

    context 'from MR diff' do
      before do
        visit diffs_project_merge_request_path(project, merge_request)
        edit_and_commit
      end

      it 'returns me to the mr' do
        expect(page).to have_content(merge_request.title)
      end
    end

    context 'from blob file path' do
      before do
        visit project_blob_path(project, tree_join(branch, file_path))
        edit_and_commit
      end

      it 'updates content' do
        expect(page).to have_content 'successfully committed'
        expect(page).to have_content 'NextFeature'
      end
    end
  end

  context 'visit blob edit' do
    context 'redirects to sign in and returns' do
      context 'as developer' do
        let(:user) { create(:user) }

        before do
          project.team << [user, :developer]
          visit project_edit_blob_path(project, tree_join(branch, file_path))
        end

        it 'redirects to sign in and returns' do
          expect(page).to have_current_path(new_user_session_path)

          gitlab_sign_in(user)

          expect(page).to have_current_path(project_edit_blob_path(project, tree_join(branch, file_path)))
        end
      end

      context 'as guest' do
        let(:user) { create(:user) }

        before do
          visit project_edit_blob_path(project, tree_join(branch, file_path))
        end

        it 'redirects to sign in and returns' do
          expect(page).to have_current_path(new_user_session_path)

          gitlab_sign_in(user)

          expect(page).to have_current_path(project_blob_path(project, tree_join(branch, file_path)))
        end
      end
    end

    context 'as developer' do
      let(:user) { create(:user) }
      let(:protected_branch) { 'protected-branch' }

      before do
        project.team << [user, :developer]
        project.repository.add_branch(user, protected_branch, 'master')
        create(:protected_branch, project: project, name: protected_branch)
        sign_in(user)
      end

      context 'on some branch' do
        before do
          visit project_edit_blob_path(project, tree_join(branch, file_path))
        end

        it 'shows blob editor with same branch' do
          expect(page).to have_current_path(project_edit_blob_path(project, tree_join(branch, file_path)))
          expect(find('.js-branch-name').value).to eq(branch)
        end
      end

      context 'with protected branch' do
        before do
          visit project_edit_blob_path(project, tree_join(protected_branch, file_path))
        end

        it 'shows blob editor with patch branch' do
          expect(find('.js-branch-name').value).to eq('patch-1')
        end
      end
    end

    context 'as master' do
      let(:user) { create(:user) }

      before do
        project.team << [user, :master]
        sign_in(user)
        visit project_edit_blob_path(project, tree_join(branch, file_path))
      end

      it 'shows blob editor with same branch' do
        expect(page).to have_current_path(project_edit_blob_path(project, tree_join(branch, file_path)))
        expect(find('.js-branch-name').value).to eq(branch)
      end
    end
  end
end
