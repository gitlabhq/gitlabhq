# frozen_string_literal: true

require 'spec_helper'

describe 'Member autocomplete', :js do
  let(:project) { create(:project, :public) }
  let(:user) { create(:user) }
  let(:author) { create(:user) }
  let(:note) { create(:note, noteable: noteable, project: noteable.project) }

  before do
    note # actually create the note
    sign_in(user)
  end

  shared_examples "open suggestions when typing @" do |resource_name|
    before do
      page.within('.new-note') do
        if resource_name == 'commit'
          find('#note_note').send_keys('@')
        else
          find('#note-body').send_keys('@')
        end
      end
    end

    it 'suggests noteable author and note author' do
      page.within('.atwho-view', visible: true) do
        expect(page).to have_content(author.username)
        expect(page).to have_content(note.author.username)
      end
    end
  end

  context 'adding a new note on a Issue' do
    let(:noteable) { create(:issue, author: author, project: project) }

    before do
      visit project_issue_path(project, noteable)
    end

    include_examples "open suggestions when typing @", 'issue'
  end

  context 'adding a new note on a Merge Request' do
    let(:project) { create(:project, :public, :repository) }
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
    let(:project) { create(:project, :public, :repository) }
    let(:noteable) { project.commit }
    let(:note) { create(:note_on_commit, project: project, commit_id: project.commit.id) }

    before do
      allow(User).to receive(:find_by_any_email)
        .with(noteable.author_email.downcase, confirmed: true).and_return(author)

      visit project_commit_path(project, noteable)
    end

    include_examples "open suggestions when typing @", 'commit'
  end
end
