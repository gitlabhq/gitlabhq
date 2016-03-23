require 'spec_helper'

feature 'Groups > Audit Events', js: true, feature: true do
  let(:user) { create(:user) }
  let(:pete) { create(:user, name: 'Pete') }
  let(:group) { create(:group) }

  before do
    group.add_owner(user)
    group.add_developer(pete)
    login_with(user)
  end

  describe 'changing a user access level' do
    it "appears in the group's audit events" do
      visit group_path(group)

      click_link 'Members'

      group_member = group.members.find_by(user_id: pete)
      page.within "#group_member_#{group_member.id}" do
        click_button 'Edit access level'
        select 'Master', from: 'group_member_access_level'
        click_button 'Save'
      end

      # This is to avoid a Capybara::Poltergeist::MouseEventFailed error
      find('a[title=Settings]').trigger('click')

      click_link 'Audit Events'

      page.within('table#audits') do
        expect(page).to have_content 'Change access level from developer to master'
        expect(page).to have_content(user.name)
        expect(page).to have_content('Pete')
      end
    end
  end
end
