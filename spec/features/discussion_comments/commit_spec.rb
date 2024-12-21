# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Thread Comments Commit', :js, feature_category: :source_code_management do
  include RepoHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:merge_request) { create(:merge_request, source_project: project) }
  let!(:commit_discussion_note1) { create(:discussion_note_on_commit, project: project) }
  let!(:commit_discussion_note2) { create(:discussion_note_on_commit, in_reply_to: commit_discussion_note1) }

  before do
    project.add_maintainer(user)
    sign_in(user)

    visit project_commit_path(project, sample_commit.id)
  end

  it_behaves_like 'thread comments for commit and snippet', 'commit'

  it 'has class .js-note-emoji' do
    expect(page).to have_css('.js-note-emoji')
  end

  it 'adds award to the correct note' do
    wait_for_requests

    find("#note_#{commit_discussion_note2.id} .js-note-emoji").click

    wait_for_requests

    first('.emoji-menu .js-emoji-btn').click

    wait_for_requests

    expect(find("#note_#{commit_discussion_note1.id}")).not_to have_css('.js-awards-block')
    expect(find("#note_#{commit_discussion_note2.id}")).to have_css('.js-awards-block')
  end
end
