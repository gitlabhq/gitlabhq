# frozen_string_literal: true

require 'spec_helper'

describe 'Projects > Settings > For a forked project', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:role) { :maintainer }

  before do
    sign_in(user)
    project.add_role(user, role)
  end

  describe 'Sidebar > Operations' do
    it 'renders the settings link in the sidebar' do
      visit project_path(project)
      wait_for_requests

      expect(page).to have_selector('a[title="Operations"]', visible: false)
    end
  end

  describe 'Settings > Operations' do
    context 'error tracking settings form' do
      let(:sentry_list_projects_url) { 'http://sentry.example.com/api/0/projects/' }

      context 'success path' do
        let(:projects_sample_response) do
          Gitlab::Utils.deep_indifferent_access(
            JSON.parse(fixture_file('sentry/list_projects_sample_response.json'))
          )
        end

        before do
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

          within '.js-error-tracking-settings' do
            click_button('Expand')
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
            click_button('Sentry | Internal')
          end

          click_button('Save changes')

          wait_for_requests

          assert_text('Your changes have been saved')
        end
      end

      context 'project dropdown fails to load' do
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

          within '.js-error-tracking-settings' do
            click_button('Expand')
          end
          check('Active')
          fill_in('error-tracking-api-host', with: 'http://sentry.example.com')
          fill_in('error-tracking-token', with: 'token')

          click_button('Connect')

          assert_text('Connection has failed. Re-check Auth Token and try again.')
        end
      end
    end

    context 'grafana integration settings form' do
      it 'successfully fills and completes the form' do
        visit project_settings_operations_path(project)

        wait_for_requests

        within '.js-grafana-integration' do
          click_button('Expand')
        end

        expect(page).to have_content('Grafana URL')
        expect(page).to have_content('API Token')
        expect(page).to have_button('Save Changes')

        fill_in('grafana-url', with: 'http://gitlab-test.grafana.net')
        fill_in('grafana-token', with: 'token')

        click_button('Save Changes')

        wait_for_requests

        assert_text('Your changes have been saved')
      end
    end
  end
end
