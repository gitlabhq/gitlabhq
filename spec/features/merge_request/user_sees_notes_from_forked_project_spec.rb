# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User sees notes from forked project', :js, feature_category: :code_review_workflow do
  include ProjectForksHelper

  let(:project) { create(:project, :public, :repository) }
  let(:user) { project.creator }
  let(:forked_project) { fork_project(project, nil, repository: true) }
  let!(:merge_request) do
    create(
      :merge_request_with_diffs,
      source_project: forked_project,
      target_project: project,
      description: 'Test merge request'
    )
  end

  before do
    create(
      :note_on_commit,
      note: 'A commit comment',
      project: forked_project,
      commit_id: merge_request.commit_shas.first
    )
    sign_in(user)
  end

  it 'user can reply to the comment', :sidekiq_might_not_need_inline do
    visit project_merge_request_path(project, merge_request)

    expect(page).to have_content('A commit comment')

    page.within('.discussion-notes') do
      find_field('Reply…').click
      scroll_to(find_field('note[note]', visible: false))
      fill_in 'note[note]', with: 'A reply comment'
      find('.js-comment-button').click
    end

    wait_for_requests

    expect(page).to have_content('A reply comment')
  end
end
