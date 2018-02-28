require 'spec_helper'

feature 'Projects > Members > Group requester cannot request access to project', :js do
  let(:user) { create(:user) }
  let(:owner) { create(:user) }
  let(:group) { create(:group, :public, :access_requestable) }
  let(:project) { create(:project, :public, :access_requestable, namespace: group) }

  background do
    group.add_owner(owner)
    sign_in(user)
    visit group_path(group)
    perform_enqueued_jobs { click_link 'Request Access' }
    visit project_path(project)
  end

  scenario 'group requester does not see the request access / withdraw access request button' do
    expect(page).not_to have_content 'Request Access'
    expect(page).not_to have_content 'Withdraw Access Request'
  end
end
