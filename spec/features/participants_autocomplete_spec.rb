# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Member autocomplete', :js do
  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:user) { create(:user) }
  let_it_be(:author) { create(:user) }

  let(:note) { create(:note, noteable: noteable, project: noteable.project) }

  before do
    note # actually create the note
    sign_in(user)
  end

  shared_examples "open suggestions when typing @" do |resource_name|
    before do
      if resource_name == 'commit'
        fill_in 'note[note]', with: '@'
      else
        fill_in 'Comment', with: '@'
      end
    end

    it 'suggests noteable author and note author' do
      expect(find_autocomplete_menu).to have_text(author.username)
      expect(find_autocomplete_menu).to have_text(note.author.username)
    end
  end

  context 'adding a new note on a Issue' do
    let(:noteable) { create(:issue, author: author, project: project) }

    before do
      stub_feature_flags(tribute_autocomplete: false)
      visit project_issue_path(project, noteable)
    end

    include_examples "open suggestions when typing @", 'issue'
  end

  describe 'when tribute_autocomplete feature flag is on' do
    context 'adding a new note on a Issue' do
      let(:noteable) { create(:issue, author: author, project: project) }

      before do
        stub_feature_flags(tribute_autocomplete: true)
        visit project_issue_path(project, noteable)

        fill_in 'Comment', with: '@'
      end

      it 'suggests noteable author and note author' do
        expect(find_tribute_autocomplete_menu).to have_content(author.username)
        expect(find_tribute_autocomplete_menu).to have_content(note.author.username)
      end
    end
  end

  context 'adding a new note on a Merge Request' do
    let(:noteable) do
      create(:merge_request, source_project: project,
                             target_project: project, author: author)
    end

    before do
      visit project_merge_request_path(project, noteable)
    end

    include_examples "open suggestions when typing @", 'merge_request'
  end

  context 'adding a new note on a Commit' do
    let(:noteable) { project.commit }
    let(:note) { create(:note_on_commit, project: project, commit_id: project.commit.id) }

    before do
      allow(User).to receive(:find_by_any_email).and_call_original
      allow(User).to receive(:find_by_any_email)
        .with(noteable.author_email.downcase, confirmed: true).and_return(author)

      visit project_commit_path(project, noteable)
    end

    include_examples "open suggestions when typing @", 'commit'
  end

  private

  def find_autocomplete_menu
    find('.atwho-view ul', visible: true)
  end

  def find_tribute_autocomplete_menu
    find('.tribute-container ul', visible: true)
  end
end
