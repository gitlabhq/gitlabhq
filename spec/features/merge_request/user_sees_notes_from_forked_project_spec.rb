require 'rails_helper'

describe 'Merge request > User sees notes from forked project', :js do
  let(:project) { create(:project, :public, :repository) }
  let(:user) { project.creator }
  let(:fork_project) { create(:project, :public, :repository, forked_from_project: project) }
  let!(:merge_request) do
    create(:merge_request_with_diffs, source_project: fork_project,
                                      target_project: project,
                                      description: 'Test merge request')
  end

  before do
    create(:note_on_commit, note: 'A commit comment',
                            project: fork_project,
                            commit_id: merge_request.commit_shas.first)
    sign_in(user)
  end

  it 'user can reply to the comment' do
    visit project_merge_request_path(project, merge_request)

    expect(page).to have_content('A commit comment')

    page.within('.discussion-notes') do
      find('.btn-text-field').click
      find('#note_note').send_keys('A reply comment')
      find('.comment-btn').click
    end

    wait_for_requests

    expect(page).to have_content('A reply comment')
  end
end
