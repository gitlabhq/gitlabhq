require 'spec_helper'

feature 'Groups > Members > User requests access', feature: true do
  let(:user) { create(:user) }
  let(:owner) { create(:user) }
  let(:group) { create(:group, :public) }

  background do
    group.add_owner(owner)
    login_as(user)
  end

  scenario 'user can request access to a group' do
    visit group_path(group)

    perform_enqueued_jobs do
      click_link 'Request Access'
    end

    expect(ActionMailer::Base.deliveries.last.to).to eq [owner.notification_email]
    expect(ActionMailer::Base.deliveries.last.subject).to match /Request to join #{group.name} group/

    expect(group.access_requested?(user)).to be_truthy
    expect(page).to have_content 'Your request for access has been queued for review.'
    expect(page).to have_content 'Withdraw Request'
  end

  scenario 'user is not listed in the group members page' do
    visit group_path(group)

    click_link 'Request Access'

    expect(group.access_requested?(user)).to be_truthy

    click_link 'Members'

    visit group_group_members_path(group)
    page.within('.content') do
      expect(page).not_to have_content(user.name)
    end
  end

  scenario 'user can withdraw its request for access' do
    visit group_path(group)
    click_link 'Request Access'

    expect(group.access_requested?(user)).to be_truthy

    click_link 'Withdraw Request'

    expect(group.access_requested?(user)).to be_falsey
    expect(page).to have_content 'You withdrawn your access request to the group.'
  end
end
