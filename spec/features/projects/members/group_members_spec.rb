require 'spec_helper'

feature 'Projects members' do
  let(:user) { create(:user) }
  let(:developer) { create(:user) }
  let(:group) { create(:group, :public, :access_requestable) }
  let(:project) { create(:project, :public, :access_requestable, creator: user, group: group) }
  let(:project_invitee) { create(:project_member, project: project, invite_token: '123', invite_email: 'test1@abc.com', user: nil) }
  let(:group_invitee) { create(:group_member, group: group, invite_token: '123', invite_email: 'test2@abc.com', user: nil) }
  let(:project_requester) { create(:user) }
  let(:group_requester) { create(:user) }

  background do
    project.add_developer(developer)
    group.add_owner(user)
    sign_in(user)
  end

  context 'with a group invitee' do
    before do
      group_invitee
      visit project_settings_members_path(project)
    end

    scenario 'does not appear in the project members page' do
      page.within first('.content-list') do
        expect(page).not_to have_content('test2@abc.com')
      end
    end
  end

  context 'with a group and a project invitee' do
    before do
      group_invitee
      project_invitee
      visit project_settings_members_path(project)
    end

    scenario 'shows the project invitee, the project developer, and the group owner' do
      page.within first('.content-list') do
        expect(page).to have_content('test1@abc.com')
        expect(page).not_to have_content('test2@abc.com')

        # Project developer
        expect(page).to have_content(developer.name)

        # Group owner
        expect(page).to have_content(user.name)
        expect(page).to have_content(group.name)
      end
    end
  end

  context 'with a group requester' do
    before do
      group.request_access(group_requester)
      visit project_settings_members_path(project)
    end

    scenario 'does not appear in the project members page' do
      page.within first('.content-list') do
        expect(page).not_to have_content(group_requester.name)
      end
    end
  end

  context 'with a group and a project requesters' do
    before do
      group.request_access(group_requester)
      project.request_access(project_requester)
      visit project_settings_members_path(project)
    end

    scenario 'shows the project requester, the project developer, and the group owner' do
      page.within first('.content-list') do
        expect(page).to have_content(project_requester.name)
        expect(page).not_to have_content(group_requester.name)
      end

      page.within all('.content-list').last do
        # Project developer
        expect(page).to have_content(developer.name)

        # Group owner
        expect(page).to have_content(user.name)
        expect(page).to have_content(group.name)
      end
    end
  end
end
