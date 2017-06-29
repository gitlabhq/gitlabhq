require 'spec_helper'

feature 'Groups > Members > Manage access requests' do
  let(:user) { create(:user) }
  let(:owner) { create(:user) }
  let(:group) { create(:group, :public, :access_requestable) }

  background do
    group.request_access(user)
    group.add_owner(owner)
    sign_in(owner)
  end

  scenario 'owner can see access requests' do
    visit group_group_members_path(group)

    expect_visible_access_request(group, user)
  end

  scenario 'owner can grant access' do
    visit group_group_members_path(group)

    expect_visible_access_request(group, user)

    perform_enqueued_jobs { click_on 'Grant access' }

    expect(ActionMailer::Base.deliveries.last.to).to eq [user.notification_email]
    expect(ActionMailer::Base.deliveries.last.subject).to match "Access to the #{group.name} group was granted"
  end

  scenario 'owner can deny access' do
    visit group_group_members_path(group)

    expect_visible_access_request(group, user)

    perform_enqueued_jobs { click_on 'Deny access' }

    expect(ActionMailer::Base.deliveries.last.to).to eq [user.notification_email]
    expect(ActionMailer::Base.deliveries.last.subject).to match "Access to the #{group.name} group was denied"
  end

  def expect_visible_access_request(group, user)
    expect(group.requesters.exists?(user_id: user)).to be_truthy
    expect(page).to have_content "Users requesting access to #{group.name} 1"
    expect(page).to have_content user.name
  end
end
