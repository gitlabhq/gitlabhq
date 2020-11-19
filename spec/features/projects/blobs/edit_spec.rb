# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Editing file blob', :js do
  include TreeHelper
  include BlobSpecHelpers

  let(:project) { create(:project, :public, :repository) }
  let(:merge_request) { create(:merge_request, source_project: project, source_branch: 'feature', target_branch: 'master') }
  let(:branch) { 'master' }
  let(:file_path) { project.repository.ls_files(project.repository.root_ref)[1] }
  let(:readme_file_path) { 'README.md' }

  context 'as a developer' do
    let(:user) { create(:user) }
    let(:role) { :developer }

    before do
      project.add_role(user, role)
      sign_in(user)
    end

    def edit_and_commit(commit_changes: true, is_diff: false)
      set_default_button('edit')
      refresh
      wait_for_requests

      if is_diff
        first('.js-diff-more-actions').click
        click_link('Edit in single-file editor')
      else
        click_link('Edit')
      end

      fill_editor(content: 'class NextFeature\\nend\\n')

      if commit_changes
        click_button 'Commit changes'
      end
    end

    def fill_editor(content: 'class NextFeature\\nend\\n')
      wait_for_requests
      execute_script("monaco.editor.getModels()[0].setValue('#{content}')")
    end

    context 'from MR diff' do
      before do
        visit diffs_project_merge_request_path(project, merge_request)
        edit_and_commit(is_diff: true)
      end

      it 'returns me to the mr' do
        expect(page).to have_content(merge_request.title)
      end
    end

    it 'updates the content of file with a number as file path' do
      project.repository.create_file(user, '1', 'test', message: 'testing', branch_name: branch)
      visit project_blob_path(project, tree_join(branch, '1'))

      edit_and_commit

      expect(page).to have_content 'NextFeature'
    end

    it 'editing a template file in a sub directory does not change path' do
      project.repository.create_file(user, 'ci/.gitlab-ci.yml', 'test', message: 'testing', branch_name: branch)
      visit project_edit_blob_path(project, tree_join(branch, 'ci/.gitlab-ci.yml'))

      expect(find_by_id('file_path').value).to eq('ci/.gitlab-ci.yml')
    end

    it 'updating file path updates syntax highlighting' do
      visit project_edit_blob_path(project, tree_join(branch, readme_file_path))
      expect(find('#editor')['data-mode-id']).to eq('markdown')

      find('#file_path').send_keys('foo.txt') do
        expect(find('#editor')['data-mode-id']).to eq('plaintext')
      end
    end

    context 'from blob file path' do
      before do
        visit project_blob_path(project, tree_join(branch, file_path))
      end

      it 'updates content' do
        edit_and_commit

        expect(page).to have_content 'successfully committed'
        expect(page).to have_content 'NextFeature'
      end

      it 'previews content' do
        edit_and_commit(commit_changes: false)
        click_link 'Preview changes'
        wait_for_requests

        old_line_count = page.all('.line_holder.old').size
        new_line_count = page.all('.line_holder.new').size

        expect(old_line_count).to be > 0
        expect(new_line_count).to be > 0
      end
    end

    context 'when rendering the preview' do
      it 'renders content with CommonMark' do
        visit project_edit_blob_path(project, tree_join(branch, readme_file_path))
        fill_editor(content: '1. one\\n  - sublist\\n')
        click_link 'Preview'
        wait_for_requests

        # the above generates two separate lists (not embedded) in CommonMark
        expect(page).to have_content('sublist')
        expect(page).not_to have_xpath('//ol//li//ul')
      end
    end
  end

  context 'visit blob edit' do
    context 'redirects to sign in and returns' do
      context 'as developer' do
        let(:user) { create(:user) }

        before do
          project.add_developer(user)
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
        project.add_developer(user)
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
        it 'shows blob editor with patch branch' do
          freeze_time do
            visit project_edit_blob_path(project, tree_join(protected_branch, file_path))

            epoch = Time.now.strftime('%s%L').last(5)

            expect(find('.js-branch-name').value).to eq "#{user.username}-protected-branch-patch-#{epoch}"
          end
        end
      end
    end

    context 'as maintainer' do
      let(:user) { create(:user) }

      before do
        project.add_maintainer(user)
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
