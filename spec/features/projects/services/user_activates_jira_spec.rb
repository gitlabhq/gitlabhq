# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User activates Jira', :js do
  include_context 'project service activation'
  include_context 'project service Jira context'

  describe 'user tests Jira Service' do
    context 'when Jira connection test succeeds' do
      before do
        server_info = { key: 'value' }.to_json
        stub_request(:get, test_url).with(basic_auth: %w(username password)).to_return(body: server_info)

        visit_project_integration('Jira')
        fill_form
        click_test_then_save_integration(expect_test_to_fail: false)
      end

      it 'activates the Jira service' do
        expect(page).to have_content('Jira settings saved and active.')
        expect(current_path).to eq(edit_project_service_path(project, :jira))
      end

      unless Gitlab.ee?
        it 'adds Jira link to sidebar menu' do
          page.within('.nav-sidebar') do
            expect(page).not_to have_link('Jira Issues')
            expect(page).not_to have_link('Issue List', visible: false)
            expect(page).not_to have_link('Open Jira', href: url, visible: false)
            expect(page).to have_link('Jira', href: url)
          end
        end
      end
    end

    context 'when Jira connection test fails' do
      it 'shows errors when some required fields are not filled in' do
        visit_project_integration('Jira')

        fill_in 'service_password', with: 'password'
        click_test_integration

        page.within('.service-settings') do
          expect(page).to have_content('This field is required.')
        end
      end

      it 'activates the Jira service' do
        stub_request(:get, test_url).with(basic_auth: %w(username password))
          .to_raise(JIRA::HTTPError.new(double(message: 'message')))

        visit_project_integration('Jira')
        fill_form
        click_test_then_save_integration

        expect(page).to have_content('Jira settings saved and active.')
        expect(current_path).to eq(edit_project_service_path(project, :jira))
      end
    end
  end

  describe 'user disables the Jira Service' do
    include JiraServiceHelper

    before do
      stub_jira_service_test
      visit_project_integration('Jira')
      fill_form(disable: true)
      click_save_integration
    end

    it 'saves but does not activate the Jira service' do
      expect(page).to have_content('Jira settings saved, but not active.')
      expect(current_path).to eq(edit_project_service_path(project, :jira))
    end

    it 'does not show the Jira link in the menu' do
      page.within('.nav-sidebar') do
        expect(page).not_to have_link('Jira', href: url)
      end
    end
  end
end
