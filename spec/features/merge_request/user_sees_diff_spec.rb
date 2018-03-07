require 'rails_helper'

describe 'Merge request > User sees diff', :js do
  include ProjectForksHelper

  let(:project) { create(:project, :public, :repository) }
  let(:merge_request) { create(:merge_request, source_project: project) }

  context 'when visit with */* as accept header' do
    it 'renders the notes' do
      create :note_on_merge_request, project: project, noteable: merge_request, note: 'Rebasing with master'

      inspect_requests(inject_headers: { 'Accept' => '*/*' }) do
        visit diffs_project_merge_request_path(project, merge_request)
      end

      # Load notes and diff through AJAX
      expect(page).to have_css('.note-text', visible: false, text: 'Rebasing with master')
      expect(page).to have_css('.diffs.tab-pane.active')
    end
  end

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

      it 'shows expanded note' do
        expect(page).to have_selector(fragment, visible: true)
      end
    end
  end

  context 'when merge request has overflow' do
    it 'displays warning' do
      allow(Commit).to receive(:max_diff_options).and_return(max_files: 3)

      visit diffs_project_merge_request_path(project, merge_request)

      page.within('.alert') do
        expect(page).to have_text("Too many changes to show. Plain diff Email patch To preserve
          performance only 3 of 3+ files are displayed.")
      end
    end
  end

  context 'when editing file' do
    let(:author_user) { create(:user) }
    let(:user) { create(:user) }
    let(:forked_project) { fork_project(project, author_user, repository: true) }
    let(:merge_request) { create(:merge_request_with_diffs, source_project: forked_project, target_project: project, author: author_user) }
    let(:changelog_id) { Digest::SHA1.hexdigest("CHANGELOG") }

    before do
      forked_project.repository.after_import
    end

    context 'as author' do
      it 'shows direct edit link' do
        sign_in(author_user)
        visit diffs_project_merge_request_path(project, merge_request)

        # Throws `Capybara::Poltergeist::InvalidSelector` if we try to use `#hash` syntax
        expect(page).to have_selector("[id=\"#{changelog_id}\"] a.js-edit-blob")
      end
    end

    context 'as user who needs to fork' do
      it 'shows fork/cancel confirmation' do
        sign_in(user)
        visit diffs_project_merge_request_path(project, merge_request)

        # Throws `Capybara::Poltergeist::InvalidSelector` if we try to use `#hash` syntax
        find("[id=\"#{changelog_id}\"] .js-edit-blob").click

        expect(page).to have_selector('.js-fork-suggestion-button', count: 1)
        expect(page).to have_selector('.js-cancel-fork-suggestion-button', count: 1)
      end
    end
  end
end
