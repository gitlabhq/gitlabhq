# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Settings > For a forked project', :js, feature_category: :incident_management do
  include ListboxHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, create_templates: :issue, namespace: user.namespace) }

  before do
    sign_in(user)
  end

  describe 'Sidebar > Monitor' do
    context 'when hide_error_tracking_features is disabled' do
      before do
        stub_feature_flags(hide_error_tracking_features: false)
      end

      it 'renders the menu in the sidebar' do
        visit project_path(project)

        within_testid('super-sidebar') do
          expect(page).to have_link('Error Tracking', visible: :hidden)
        end
      end
    end

    context 'when hide_error_tracking_features is enabled' do
      it 'renders the menu in the sidebar' do
        visit project_path(project)

        within_testid('super-sidebar') do
          expect(page).not_to have_link('Error Tracking', visible: :hidden)
        end
      end
    end
  end

  describe 'Settings > Monitor' do
    describe 'Incidents' do
      let(:create_issue) { 'Create an incident. Incidents are created for each alert triggered.' }
      let(:send_email) { 'Send a single email notification to Owners and Maintainers for new alerts.' }

      before do
        create(:project_incident_management_setting, send_email: true, project: project)
        visit project_settings_operations_path(project)

        wait_for_requests
        click_settings_tab
      end

      it 'renders form for incident management' do
        expect(page).to have_selector('h2', text: 'Incidents')
      end

      it 'sets correct default values' do
        expect(find_field(create_issue)).not_to be_checked
        expect(find_field(send_email)).to be_checked
      end

      it 'updates form values' do
        check(create_issue)
        uncheck(send_email)
        click_on('No template selected')
        select_listbox_item('bug')

        save_form
        click_settings_tab

        expect(find_field(create_issue)).to be_checked
        expect(find_field(send_email)).not_to be_checked
        expect(page).to have_selector(:id, 'alert-integration-settings-issue-template', text: 'bug')
      end

      def click_settings_tab
        within_testid 'alert-integration-settings' do
          click_link 'Alert settings'
        end
      end

      def save_form
        within_testid 'alert-integration-settings' do
          click_button 'Save changes'
        end

        wait_for_all_requests
      end
    end

    describe 'error tracking settings form' do
      let(:sentry_list_projects_url) { 'http://sentry.example.com/api/0/projects/' }

      context 'when project dropdown is loaded' do
        let(:projects_sample_response) do
          Gitlab::Utils.deep_indifferent_access(
            Gitlab::Json.parse(fixture_file('sentry/list_projects_sample_response.json'))
          )
        end

        before do
          stub_feature_flags(hide_error_tracking_features: false)
          WebMock.stub_request(:get, sentry_list_projects_url)
          .to_return(
            status: 200,
            headers: { 'Content-Type' => 'application/json' },
            body: projects_sample_response.to_json
          )
        end

        it 'successfully fills and submits the form' do
          visit project_settings_operations_path(project)

          wait_for_requests

          within '#js-error-tracking-settings' do
            click_button('Expand')
            choose('cloud-hosted Sentry')
          end

          expect(page).to have_content('Sentry API URL')
          expect(page.body).to include('Error Tracking')
          expect(page).to have_button('Connect')

          check('Active')
          fill_in('error-tracking-api-host', with: 'http://sentry.example.com')
          fill_in('error-tracking-token', with: 'token')

          click_button('Connect')

          within('div#project-dropdown') do
            click_button('Select project')
            find('li', text: 'Sentry | internal').click
          end

          click_button('Save changes')

          wait_for_requests

          assert_text('Your changes have been saved')
        end
      end

      context 'when project dropdown fails to load' do
        before do
          WebMock.stub_request(:get, sentry_list_projects_url)
          .to_return(
            status: 400,
            headers: { 'Content-Type' => 'application/json' },
            body: {
              message: 'Sentry response code: 401'
            }.to_json
          )
        end

        it 'displays error message' do
          visit project_settings_operations_path(project)

          wait_for_requests

          within '#js-error-tracking-settings' do
            click_button('Expand')
            choose('cloud-hosted Sentry')
            check('Active')
          end

          fill_in('error-tracking-api-host', with: 'http://sentry.example.com')
          fill_in('error-tracking-token', with: 'token')

          click_button('Connect')

          assert_text('Connection failed. Check Auth Token and try again.')
        end
      end

      context 'with integrated error tracking backend' do
        before do
          stub_feature_flags(hide_error_tracking_features: false)
        end

        it 'successfully fills and submits the form' do
          visit project_settings_operations_path(project)

          wait_for_requests

          within '#js-error-tracking-settings' do
            click_button('Expand')
          end

          expect(page).to have_content('Error tracking backend')

          within '#js-error-tracking-settings' do
            check('Active')
            choose('GitLab')
          end

          expect(page).not_to have_content('Sentry API URL')

          click_button('Save changes')

          wait_for_requests

          assert_text('Your changes have been saved')

          within '#js-error-tracking-settings' do
            click_button('Expand')
          end

          expect(page).to have_content('Paste this Data Source Name (DSN) into your Sentry SDK')
        end
      end
    end
  end
end
