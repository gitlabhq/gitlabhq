# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User sees diff', :js, feature_category: :code_review_workflow do
  include ProjectForksHelper
  include RepoHelpers
  include MergeRequestDiffHelpers

  let(:project) { create(:project, :public, :repository) }
  let(:merge_request) { create(:merge_request, source_project: project) }

  context 'when linking to note' do
    describe 'with unresolved note' do
      let(:note) { create :diff_note_on_merge_request, project: project, noteable: merge_request }
      let(:fragment) { "#note_#{note.id}" }

      before do
        visit "#{diffs_project_merge_request_path(project, merge_request)}#{fragment}"
      end

      it 'shows expanded note' do
        expect(page).to have_selector(fragment, visible: true)
      end
    end

    describe 'with resolved note' do
      let(:note) { create :diff_note_on_merge_request, :resolved, project: project, noteable: merge_request }
      let(:fragment) { "#note_#{note.id}" }

      before do
        visit "#{diffs_project_merge_request_path(project, merge_request)}#{fragment}"
      end

      it 'shows expanded note', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/391239' do
        expect(page).to have_selector(fragment, visible: true)
      end
    end
  end

  context 'when linking to a line' do
    let(:note) { create :diff_note_on_merge_request, project: project, noteable: merge_request }
    let(:line) { note.diff_file.highlighted_diff_lines.last }
    let(:line_code) { line.line_code }

    before do
      visit "#{diffs_project_merge_request_path(project, merge_request)}##{line_code}"
    end

    it 'shows the linked line', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/496702' do
      expect(page).to have_selector("[id='#{line_code}']", visible: true, obscured: false)
    end
  end

  context 'when merge request has overflow' do
    it 'displays warning' do
      allow(Commit).to receive(:max_diff_options).and_return(max_files: 3)
      allow_any_instance_of(DiffHelper).to receive(:render_overflow_warning?).and_return(true)

      visit diffs_project_merge_request_path(project, merge_request)

      page.within('.gl-alert') do
        expect(page).to have_text("Some changes are not shown. For a faster browsing experience, only 3 of 3+ files are shown. Download one of the files below to see all changes. Plain diff Patches")
        expect(page).to have_link("Plain diff", href: merge_request_path(merge_request, format: :diff))
        expect(page).to have_link("Patches", href: merge_request_path(merge_request, format: :patch))
      end
    end
  end

  context 'when editing file' do
    let(:author_user) { create(:user) }
    let(:user) { create(:user) }
    let(:forked_project) { fork_project(project, author_user, repository: true) }
    let(:merge_request) { create(:merge_request_with_diffs, source_project: forked_project, target_project: project, author: author_user) }
    let(:changelog_id) { Digest::SHA1.hexdigest("CHANGELOG") }

    context 'as author' do
      it 'contains direct edit link', :sidekiq_might_not_need_inline do
        sign_in(author_user)
        visit diffs_project_merge_request_path(project, merge_request)

        first(".js-diff-more-actions").click

        expect(page).to have_selector(".js-edit-blob")
      end
    end

    context 'as user who needs to fork' do
      it 'shows fork/cancel confirmation', :sidekiq_might_not_need_inline, quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/337477' do
        sign_in(user)
        visit diffs_project_merge_request_path(project, merge_request)

        find_by_scrolling("[id=\"#{changelog_id}\"]")

        # Throws `Capybara::Poltergeist::InvalidSelector` if we try to use `#hash` syntax
        find("[id=\"#{changelog_id}\"] .js-diff-more-actions").click
        find("[id=\"#{changelog_id}\"] .js-edit-blob").click

        expect(page).to have_selector('.js-fork-suggestion-button', count: 1)
        expect(page).to have_selector('.js-cancel-fork-suggestion-button', count: 1)
      end
    end

    context 'when file contains html' do
      let(:current_user) { project.first_owner }
      let(:branch_name) { "test_branch" }

      it 'escapes any HTML special characters in the diff chunk header' do
        file_content =
          <<~CONTENT
          function foo<input> {
            let a = 1;
            let b = 2;
            let c = 3;
            let d = 3;
          }
          CONTENT

        new_file_content =
          <<~CONTENT
          function foo<input> {
            let a = 1;
            let b = 2;
            let c = 3;
            let x = 3;
          }
          CONTENT

        file_name = 'xss_file.rs'
        file_hash = Digest::SHA1.hexdigest(file_name)

        create_file('master', file_name, file_content)
        merge_request = create(:merge_request, source_project: project)
        create_file(merge_request.source_branch, file_name, new_file_content)

        project.commit(merge_request.source_branch)

        visit diffs_project_merge_request_path(project, merge_request)

        find_by_scrolling("[id='#{file_hash}']")

        expect(page).to have_text("function foo<input> {")
        expect(page).to have_css(".line[lang='rust'] .k")
      end
    end

    context 'when file is stored in LFS' do
      let(:merge_request) { create(:merge_request, source_project: project) }
      let(:current_user) { project.first_owner }

      context 'when LFS is enabled on the project' do
        before do
          allow(Gitlab.config.lfs).to receive(:enabled).and_return(true)
          project.update_attribute(:lfs_enabled, true)

          create_file('master', file_name, project.repository.blob_at('master', 'files/lfs/lfs_object.iso').data)

          visit diffs_project_merge_request_path(project, merge_request)
        end

        context 'when file is an image', :js do
          let(:file_name) { 'a/image.png' }

          it 'shows an error message' do
            expect(page).not_to have_content('could not be displayed: it is stored in LFS')
          end
        end

        context 'when file is not an image' do
          let(:file_name) { 'a/ruby.rb' }

          it 'shows an error message' do
            expect(page).to have_content('source diff could not be displayed: it is stored in LFS')
          end
        end
      end

      context 'when LFS is not enabled' do
        let(:file_name) { 'a/lfs_object.iso' }

        before do
          allow(Gitlab.config.lfs).to receive(:disabled).and_return(true)
          project.update_attribute(:lfs_enabled, false)

          create_file('master', file_name, project.repository.blob_at('master', 'files/lfs/lfs_object.iso').data)

          visit diffs_project_merge_request_path(project, merge_request)
        end

        it 'displays the diff' do
          expect(page).to have_content('size 1575078')
        end
      end
    end

    def create_file(branch_name, file_name, content)
      Files::CreateService.new(
        project,
        current_user,
        start_branch: branch_name,
        branch_name: branch_name,
        commit_message: "Create file",
        file_path: file_name,
        file_content: content
      ).execute

      project.commit(branch_name)
    end
  end
end
