# frozen_string_literal: true

require 'spec_helper'

describe 'User activates Jira', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project) }

  let(:url) { 'http://jira.example.com' }
  let(:test_url) { 'http://jira.example.com/rest/api/2/serverInfo' }

  def fill_form(disabled: false)
    find('input[name="service[active]"] + button').click if disabled

    fill_in 'service_url', with: url
    fill_in 'service_username', with: 'username'
    fill_in 'service_password', with: 'password'
    fill_in 'service_jira_issue_transition_id', with: '25'
  end

  before do
    project.add_maintainer(user)
    sign_in(user)

    visit project_settings_integrations_path(project)
  end

  describe 'user sets and activates Jira Service' do
    context 'when Jira connection test succeeds' do
      before do
        server_info = { key: 'value' }.to_json
        WebMock.stub_request(:get, test_url).with(basic_auth: %w(username password)).to_return(body: server_info)

        click_link('Jira')
        fill_form
        click_button('Test settings and save changes')
        wait_for_requests
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
        click_link('Jira')

        fill_in 'service_password', with: 'password'
        click_button('Test settings and save changes')

        page.within('.service-settings') do
          expect(page).to have_content('This field is required.')
        end
      end

      it 'activates the Jira service' do
        WebMock.stub_request(:get, test_url).with(basic_auth: %w(username password))
          .to_raise(JIRA::HTTPError.new(double(message: 'message')))

        click_link('Jira')
        fill_form
        click_button('Test settings and save changes')
        wait_for_requests

        expect(find('.flash-container-page')).to have_content 'Test failed. message'
        expect(find('.flash-container-page')).to have_content 'Save anyway'

        find('.flash-alert .flash-action').click
        wait_for_requests

        expect(page).to have_content('Jira activated.')
        expect(current_path).to eq(project_settings_integrations_path(project))
      end
    end
  end

  describe 'user disables the Jira Service' do
    before do
      click_link('Jira')
      fill_form(disabled: true)
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
