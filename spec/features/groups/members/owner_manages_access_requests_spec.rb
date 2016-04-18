require 'spec_helper'

feature 'Groups > Members > Owner manages access requests', feature: true do
  let(:user) { create(:user) }
  let(:owner) { create(:user) }
  let(:group) { create(:group, :public) }

  background do
    group.request_access(user)
    group.add_owner(owner)
    login_as(owner)
  end

  scenario 'owner can see access requests' do
    visit group_group_members_path(group)

    expect_visible_access_request(group, user)
  end

  scenario 'master can grant access' do
    visit group_group_members_path(group)

    expect_visible_access_request(group, user)

    perform_enqueued_jobs do
      click_on 'Grant access'
    end

    expect(ActionMailer::Base.deliveries.last.to).to eq [user.notification_email]
    expect(ActionMailer::Base.deliveries.last.subject).to match /Access to #{group.name} group was granted/
  end

  scenario 'master can deny access' do
    visit group_group_members_path(group)

    expect_visible_access_request(group, user)

    perform_enqueued_jobs do
      click_on 'Deny access'
    end

    expect(ActionMailer::Base.deliveries.last.to).to eq [user.notification_email]
    expect(ActionMailer::Base.deliveries.last.subject).to match /Access to #{group.name} group was denied/
  end


  def expect_visible_access_request(group, user)
    expect(group.access_requested?(user)).to be_truthy
    expect(page).to have_content "#{group.name} access requests (1)"
    expect(page).to have_content user.name
  end
end
