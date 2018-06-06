require 'spec_helper'

feature 'Groups > Audit Events', :js do
  let(:user) { create(:user) }
  let(:pete) { create(:user, name: 'Pete') }
  let(:group) { create(:group) }

  before do
    group.add_owner(user)
    group.add_developer(pete)
    sign_in(user)
  end

  context 'unlicensed' do
    before do
      stub_licensed_features(audit_events: false)
    end

    it 'returns 404' do
      reqs = inspect_requests do
        visit group_audit_events_path(group)
      end

      expect(reqs.first.status_code).to eq(404)
    end

    it 'does not have Audit Events button in head nav bar' do
      visit edit_group_path(group)

      expect(page).not_to have_link('Audit Events')
    end
  end

  it 'has Audit Events button in head nav bar' do
    visit edit_group_path(group)

    expect(page).to have_link('Audit Events')
  end

  describe 'changing a user access level' do
    it "appears in the group's audit events" do
      visit group_group_members_path(group)

      group_member = group.members.find_by(user_id: pete)

      page.within "#group_member_#{group_member.id}" do
        click_button 'Developer'
        click_link 'Maintainer'
      end

      find(:link, text: 'Settings').click

      click_link 'Audit Events'

      page.within('table#audits') do
        expect(page).to have_content 'Change access level from developer to maintainer'
        expect(page).to have_content(user.name)
        expect(page).to have_content('Pete')
      end
    end
  end
end
