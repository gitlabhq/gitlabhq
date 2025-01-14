# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Editing file blob', :js, feature_category: :source_code_management do
  include Features::SourceEditorSpecHelpers
  include TreeHelper
  include Features::BlobSpecHelpers

  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project, source_branch: 'feature', target_branch: 'master') }
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
      if is_diff
        first('.js-diff-more-actions').click
        click_link('Edit in single-file editor')
      else
        edit_in_single_file_editor
      end

      # Append object_id so that the content varies between specs. If we don't do this then depending on test order
      # there may be no diff and nothing to render.
      fill_editor(content: "class NextFeature#{object_id}\\nend\\n")

      return unless commit_changes

      click_button('Commit changes')

      within_testid('commit-change-modal') do
        click_button('Commit changes')
      end
    end

    def fill_editor(content: 'class NextFeature\\nend\\n')
      wait_for_requests
      editor_set_value(content)
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

    context 'blob edit toolbar' do
      def has_toolbar_buttons
        toolbar_buttons = [
          "Add bold text",
          "Add italic text",
          "Add strikethrough text",
          "Insert a quote",
          "Insert code",
          "Add a link",
          "Add a bullet list",
          "Add a numbered list",
          "Add a checklist",
          "Add a collapsible section",
          "Add a table"
        ]
        visit project_edit_blob_path(project, tree_join(branch, readme_file_path))
        buttons = page.all('.file-buttons .md-header-toolbar button[type="button"]')
        expect(buttons.length).to eq(toolbar_buttons.length)
        toolbar_buttons.each_with_index do |button_title, i|
          expect(buttons[i]['title']).to include(button_title)
        end
      end

      it "has defined set of toolbar buttons when the flag is on" do
        stub_feature_flags(source_editor_toolbar: true)
        has_toolbar_buttons
      end

      it "has defined set of toolbar buttons when the flag is off" do
        stub_feature_flags(source_editor_toolbar: false)
        has_toolbar_buttons
      end
    end

    context 'from blob file path' do
      before do
        visit project_blob_path(project, tree_join(branch, file_path))
      end

      it 'updates content' do
        edit_and_commit

        expect(page).to have_content 'committed successfully.'
        expect(page).to have_content 'NextFeature'
      end

      it 'previews content' do
        edit_and_commit(commit_changes: false)
        click_link 'Preview changes'
        wait_for_requests

        expect(page).to have_css('.line_holder.new')
      end
    end

    context 'when rendering the preview' do
      it 'renders content with CommonMark' do
        visit project_edit_blob_path(project, tree_join(branch, readme_file_path))
        fill_editor(content: '1. one\\n  - sublist\\n')
        click_on "Preview"
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
      let_it_be(:user) { create(:user) }
      let(:protected_branch) { 'protected-branch' }

      before_all do
        project.add_developer(user)
      end

      before do
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

          click_button('Commit changes')

          expect(page).to have_selector('code', text: branch)
        end
      end

      context 'with protected branch' do
        it 'shows blob editor with patch branch and option to create MR' do
          freeze_time do
            visit project_edit_blob_path(project, tree_join(protected_branch, file_path))

            click_button('Commit changes')

            epoch = Time.zone.now.strftime('%s%L').last(5)
            expect(page).to have_checked_field _('Create a merge request for this change')
            expect(find_field('branch_name').value).to eq "#{user.username}-protected-branch-patch-#{epoch}"
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

        click_button('Commit changes')

        expect(page).to have_selector('code', text: branch)
      end
    end
  end
end
