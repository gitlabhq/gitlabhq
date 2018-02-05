require 'rails_helper'

describe 'Merge request > User assigns themselves' do
  let(:project) { create(:project, :public, :repository) }
  let(:user) { project.creator }
  let(:issue1) { create(:issue, project: project) }
  let(:issue2) { create(:issue, project: project) }
  let(:merge_request) { create(:merge_request, :simple, source_project: project, author: user, description: "fixes #{issue1.to_reference} and #{issue2.to_reference}") }

  context 'logged in as a member of the project' do
    before do
      sign_in(user)
      visit project_merge_request_path(project, merge_request)
    end

    it 'updates related issues', :js do
      click_link 'Assign yourself to these issues'

      expect(page).to have_content '2 issues have been assigned to you'
    end

    it 'returns user to the merge request', :js do
      click_link 'Assign yourself to these issues'

      expect(page).to have_content merge_request.description
    end

    context 'when related issues are already assigned' do
      before do
        [issue1, issue2].each { |issue| issue.update!(assignees: [user]) }
      end

      it 'does not display if related issues are already assigned' do
        expect(page).not_to have_content 'Assign yourself'
      end
    end
  end

  context 'logged in as a non-member of the project' do
    before do
      sign_in(create(:user))
      visit project_merge_request_path(project, merge_request)
    end

    it 'does not not show assignment link' do
      expect(page).not_to have_content 'Assign yourself'
    end
  end
end
