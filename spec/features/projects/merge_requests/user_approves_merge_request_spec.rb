require 'spec_helper'

describe 'User approves a merge request', :js do
  let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  let(:project) { create(:project, :repository, approvals_before_merge: 1) }
  let(:user) { create(:user) }
  let(:user2) { create(:user) }

  before do
    project.add_developer(user)
    sign_in(user)
  end

  context 'when user can approve' do
    before do
      visit(merge_request_path(merge_request))
    end

    it 'approves a merge request' do
      page.within('.mr-state-widget') do
        expect(page).to have_button('Merge', disabled: true)

        click_button('Approve')

        expect(page).to have_button('Merge', disabled: false)
      end
    end
  end

  context 'when user cannot approve' do
    before do
      merge_request.approvers.create(user_id: user2.id)

      visit(merge_request_path(merge_request))
    end

    it 'does not approves a merge request' do
      page.within('.mr-state-widget') do
        expect(page).to have_button('Merge', disabled: true)
        expect(page).not_to have_button('Approve')
        expect(page).to have_content('Requires 1 more approval')
      end
    end
  end
end
