# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Member autocomplete', :js, feature_category: :groups_and_projects do
  include Features::AutocompleteHelpers

  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:user) { create(:user) }
  let_it_be(:author) { create(:user) }

  let(:note) { create(:note, noteable: noteable, project: noteable.project) }
  let(:noteable) { create(:issue, author: author, project: project) }

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

  context 'for a member of a private group invited to the project' do
    let_it_be(:private_group) { create(:group, :private) }
    let_it_be(:private_group_member) { create(:user, username: 'private-a') }

    before_all do
      project.add_developer user

      private_group.add_developer private_group_member

      create(:project_group_link, group: private_group, project: project)
    end

    it 'suggests member of private group' do
      visit project_issue_path(project, noteable)
      fill_in 'Comment', with: '@priv'

      expect(find_autocomplete_menu).to have_text(private_group_member.username)
    end
  end

  context 'adding a new note on a Issue' do
    before do
      visit project_issue_path(project, noteable)
    end

    include_examples "open suggestions when typing @", 'issue'
  end

  context 'adding a new note on a Merge Request' do
    let(:noteable) do
      create(:merge_request, source_project: project, target_project: project, author: author)
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
end
