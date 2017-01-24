require 'spec_helper'

describe 'Target branch', feature: true do
  let(:user) { create(:user) }
  let(:merge_request) { create(:merge_request) }
  let(:project) { merge_request.project }

  def path_to_merge_request
    namespace_project_merge_request_path(
      project.namespace,
      project, merge_request
    )
  end

  before do
    login_as user
    project.team << [user, :master]
  end

  it 'shows link to target branch' do
    visit path_to_merge_request
    expect(page).to have_link('feature', href: namespace_project_commits_path(project.namespace, project, merge_request.target_branch))
  end

  context 'when branch was deleted' do
    before do
      DeleteBranchService.new(project, user).execute('feature')
      visit path_to_merge_request
    end

    it 'shows a message about missing target branch' do
      expect(page).to have_content(
        'Target branch feature does not exist'
      )
    end

    it 'does not show link to target branch' do
      expect(page).not_to have_link('feature')
    end
  end
end
