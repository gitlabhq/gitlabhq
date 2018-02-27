require 'spec_helper'

describe 'User approves a merge request', :js do
  let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  let(:project) { create(:project, :repository, approvals_before_merge: 1) }
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:user3) { create(:user) }

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

  context 'when a merge request is approved additionally' do
    before do
      project.add_developer(user2)
      project.add_developer(user3)
    end

    it 'shows multiple approvers beyond the needed count' do
      visit(merge_request_path(merge_request))

      click_button('Approve')
      wait_for_requests

      sign_out(user)

      sign_in_visit_merge_request(user2, true)
      sign_in_visit_merge_request(user3, true)

      expect(all('.js-approver-list-member').count).to eq(3)
    end

    it "doesn't show the add approval when a merge request is closed" do
      merge_request_closed = create(:merge_request, :closed, source_project: project, target_project: project)
      create(:approval, merge_request: merge_request_closed, user: user)

      sign_in(user2)

      visit(merge_request_path(merge_request_closed))
      wait_for_requests

      expect(page).not_to have_button('Approve')
      expect(page).not_to have_button('Add approval')
    end

    def sign_in_visit_merge_request(user, additional_approver = false)
      sign_in(user)
      visit(merge_request_path(merge_request))
      button_text = additional_approver ? 'Add approval' : 'Approve'
      click_button(button_text)
      wait_for_requests
      sign_out(user)
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
