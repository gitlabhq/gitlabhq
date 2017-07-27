require 'spec_helper'

describe 'Admin::AuditLogs', feature: true, js: true do
  include Select2Helper

  let(:user) { create(:user) }

  before do
    sign_in(create(:admin))
  end

  context 'unlicensed' do
    before do
      stub_licensed_features(admin_audit_log: false)
    end

    it 'returns 404' do
      visit admin_audit_logs_path

      expect(page.status_code).to eq(404)
    end
  end

  context 'licensed' do
    before do
      stub_licensed_features(admin_audit_log: true)
    end

    it 'has Audit Log button in head nav bar' do
      visit admin_audit_logs_path

      expect(page).to have_link('Audit Log', href: admin_audit_logs_path)
    end

    describe 'user events' do
      before do
        AuditEventService.new(user, user, with: :ldap)
          .for_authentication.security_event

        visit admin_audit_logs_path
      end

      it 'filters by user' do
        filter_by_type('User Events')

        click_button 'User'
        wait_for_requests

        within '.dropdown-menu-user' do
          click_link user.name
        end

        wait_for_requests

        expect(page).to have_content('Signed in with LDAP authentication')
      end
    end

    describe 'group events' do
      let(:group_member) { create(:group_member, user: user) }

      before do
        AuditEventService.new(user, group_member.group, { action: :create })
          .for_member(group_member).security_event

        visit admin_audit_logs_path
      end

      it 'filters by group' do
        filter_by_type('Group Events')

        click_button 'Group'
        find('.group-item-select').click
        wait_for_requests
        find('.select2-results').click

        find('#events-table td', match: :first)

        expect(page).to have_content('Added user access as Owner')
      end
    end

    describe 'project events' do
      let(:project_member) { create(:project_member, user: user) }

      before do
        AuditEventService.new(user, project_member.project, { action: :destroy })
          .for_member(project_member).security_event

        visit admin_audit_logs_path
      end

      it 'filters by project' do
        filter_by_type('Project Events')

        click_button 'Project'
        find('.project-item-select').click
        wait_for_requests
        find('.select2-results').click

        find('#events-table td', match: :first)

        expect(page).to have_content('Removed user access')
      end
    end
  end

  def filter_by_type(type)
    click_button 'Events'
    within '.dropdown-menu-type' do
      click_link type
    end

    wait_for_requests
  end
end
