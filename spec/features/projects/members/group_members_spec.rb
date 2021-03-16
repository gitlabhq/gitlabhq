# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects members', :js do
  include Spec::Support::Helpers::Features::MembersHelpers

  let(:user) { create(:user) }
  let(:developer) { create(:user) }
  let(:group) { create(:group, :public) }
  let(:project) { create(:project, :public, creator: user, group: group) }
  let(:project_invitee) { create(:project_member, project: project, invite_token: '123', invite_email: 'test1@abc.com', user: nil) }
  let(:group_invitee) { create(:group_member, group: group, invite_token: '123', invite_email: 'test2@abc.com', user: nil) }
  let(:project_requester) { create(:user) }
  let(:group_requester) { create(:user) }

  before do
    project.add_developer(developer)
    group.add_owner(user)
    sign_in(user)
  end

  context 'with a group invitee' do
    before do
      group_invitee
      visit project_project_members_path(project)
    end

    it 'does not appear in the project members page' do
      expect(members_table).not_to have_content('test2@abc.com')
    end
  end

  context 'with a group' do
    it 'shows group and project members by default' do
      visit project_project_members_path(project)

      expect(members_table).to have_content(developer.name)
      expect(members_table).to have_content(user.name)
      expect(members_table).to have_content(group.name)
    end

    it 'shows project members only if requested' do
      visit project_project_members_path(project, with_inherited_permissions: 'exclude')

      expect(members_table).to have_content(developer.name)
      expect(members_table).not_to have_content(user.name)
      expect(members_table).not_to have_content(group.name)
    end

    it 'shows group members only if requested' do
      visit project_project_members_path(project, with_inherited_permissions: 'only')

      expect(members_table).not_to have_content(developer.name)
      expect(members_table).to have_content(user.name)
      expect(members_table).to have_content(group.name)
    end
  end

  context 'with a group, a project invitee, and a project requester' do
    before do
      group.request_access(group_requester)
      project.request_access(project_requester)
      group_invitee
      project_invitee
      visit project_project_members_path(project)
    end

    it 'shows the group owner' do
      expect(members_table).to have_content(user.name)
      expect(members_table).to have_content(group.name)
    end

    it 'shows the project developer' do
      expect(members_table).to have_content(developer.name)
    end

    it 'shows the project invitee' do
      click_link 'Invited'

      expect(members_table).to have_content('test1@abc.com')
      expect(members_table).not_to have_content('test2@abc.com')
    end

    it 'shows the project requester' do
      click_link 'Access requests'

      expect(members_table).to have_content(project_requester.name)
      expect(members_table).not_to have_content(group_requester.name)
    end
  end

  context 'with a group requester' do
    before do
      stub_feature_flags(invite_members_group_modal: false)
      group.request_access(group_requester)
      visit project_project_members_path(project)
    end

    it 'does not appear in the project members page' do
      expect(page).not_to have_link('Access requests')
      expect(members_table).not_to have_content(group_requester.name)
    end
  end

  context 'showing status of members' do
    it 'shows the status' do
      create(:user_status, user: user, emoji: 'smirk', message: 'Authoring this object')

      visit project_project_members_path(project)

      expect(first_row).to have_selector('gl-emoji[data-name="smirk"]')
    end
  end
end
