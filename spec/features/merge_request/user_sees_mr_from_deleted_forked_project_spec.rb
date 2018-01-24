require 'rails_helper'

describe 'Merge request > User sees MR from deleted forked project', :js do
  let(:project) { create(:project, :public, :repository) }
  let(:user) { project.creator }
  let(:fork_project) { create(:project, :public, :repository, forked_from_project: project) }
  let!(:merge_request) do
    create(:merge_request_with_diffs, source_project: fork_project,
                                      target_project: project,
                                      description: 'Test merge request')
  end

  before do
    MergeRequests::MergeService.new(project, user).execute(merge_request)
    fork_project.destroy!
    sign_in(user)
    visit project_merge_request_path(project, merge_request)
  end

  it 'user can access merge request' do
    expect(page).to have_content 'Test merge request'
    expect(page).to have_content "(removed):#{merge_request.source_branch}"
  end
end
