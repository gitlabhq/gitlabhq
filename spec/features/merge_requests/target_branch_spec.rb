require 'spec_helper'

describe 'Target branch', feature: true, js: true do
  let(:user) { create(:user) }
  let(:merge_request) { create(:merge_request) }
  let(:project) { merge_request.project }

  def path_to_merge_request
    project_merge_request_path(project, merge_request)
  end

  before do
    sign_in user
    project.team << [user, :master]
  end

  context 'when branch was deleted' do
    before do
      DeleteBranchService.new(project, user).execute('feature')
      visit path_to_merge_request
    end

    it 'shows a message about missing target branch' do
      expect(page).to have_content(
        'Target branch does not exist'
      )
    end

    it 'does not show link to target branch' do
      expect(page).not_to have_selector('.mr-widget-body .js-branch-text a')
    end
  end
end
