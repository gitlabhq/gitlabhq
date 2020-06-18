# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User activates Jira', :js do
  include_context 'project service activation'

  let(:url) { 'http://jira.example.com' }
  let(:test_url) { 'http://jira.example.com/rest/api/2/serverInfo' }

  def fill_form(disable: false)
    click_active_toggle if disable

    fill_in 'service_url', with: url
    fill_in 'service_username', with: 'username'
    fill_in 'service_password', with: 'password'
    fill_in 'service_jira_issue_transition_id', with: '25'
  end

  describe 'user sets and activates Jira Service' do
    context 'when Jira connection test succeeds' do
      before do
        server_info = { key: 'value' }.to_json
        stub_request(:get, test_url).with(basic_auth: %w(username password)).to_return(body: server_info)

        visit_project_integration('Jira')
        fill_form
        click_test_integration
      end

      it 'activates the Jira service' do
        expect(page).to have_content('Jira activated.')
        expect(current_path).to eq(project_settings_integrations_path(project))
      end

      it 'shows the Jira link in the menu' do
        page.within('.nav-sidebar') do
          expect(page).to have_link('Jira', href: url)
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

        expect(page).to have_content('Jira activated.')
        expect(current_path).to eq(project_settings_integrations_path(project))
      end
    end
  end

  describe 'user disables the Jira Service' do
    before do
      visit_project_integration('Jira')
      fill_form(disable: true)
      click_button('Save changes')
    end

    it 'saves but does not activate the Jira service' do
      expect(page).to have_content('Jira settings saved, but not activated.')
      expect(current_path).to eq(project_settings_integrations_path(project))
    end

    it 'does not show the Jira link in the menu' do
      page.within('.nav-sidebar') do
        expect(page).not_to have_link('Jira', href: url)
      end
    end
  end
end
