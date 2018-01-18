require 'rails_helper'

feature 'Merge request > User sees approval widget', :js do
  let(:project) { create(:project, :public, :repository, approvals_before_merge: 1) }
  let(:user) { project.creator }
  let(:merge_request) { create(:merge_request, source_project: project) }

  context 'when merge when discussions resolved is active' do
    let(:project) do
      create(:project, :repository,
        approvals_before_merge: 1,
        only_allow_merge_if_all_discussions_are_resolved: true)
    end

    before do
      sign_in(user)

      visit project_merge_request_path(project, merge_request)
    end

    it 'does not show checking ability text' do
      expect(find('.mr-widget-approvals-container')).not_to have_text('Checking ability to merge automatically')
      expect(find('.mr-widget-approvals-container')).to have_selector('.approvals-body')
    end
  end
end
