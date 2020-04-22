# frozen_string_literal: true

require 'spec_helper'

describe 'User activates issue tracker', :js do
  include_context 'project service activation'

  let(:url) { 'http://tracker.example.com' }

  def fill_form(disable: false, skip_new_issue_url: false)
    click_active_toggle if disable

    fill_in 'service_project_url', with: url
    fill_in 'service_issues_url', with: "#{url}/:id"

    fill_in 'service_new_issue_url', with: url unless skip_new_issue_url
  end

  shared_examples 'external issue tracker activation' do |tracker:, skip_new_issue_url: false|
    describe 'user sets and activates the Service' do
      context 'when the connection test succeeds' do
        before do
          stub_request(:head, url).to_return(headers: { 'Content-Type' => 'application/json' })

          visit_project_integration(tracker)
          fill_form(skip_new_issue_url: skip_new_issue_url)

          click_test_integration
        end

        it 'activates the service' do
          expect(page).to have_content("#{tracker} activated.")
          expect(current_path).to eq(project_settings_integrations_path(project))
        end

        it 'shows the link in the menu' do
          page.within('.nav-sidebar') do
            expect(page).to have_link(tracker, href: url)
          end
        end
      end

      context 'when the connection test fails' do
        it 'activates the service' do
          stub_request(:head, url).to_raise(Gitlab::HTTP::Error)

          visit_project_integration(tracker)
          fill_form(skip_new_issue_url: skip_new_issue_url)

          click_test_then_save_integration

          expect(page).to have_content("#{tracker} activated.")
          expect(current_path).to eq(project_settings_integrations_path(project))
        end
      end
    end

    describe 'user disables the service' do
      before do
        visit_project_integration(tracker)
        fill_form(disable: true, skip_new_issue_url: skip_new_issue_url)

        click_button('Save changes')
      end

      it 'saves but does not activate the service' do
        expect(page).to have_content("#{tracker} settings saved, but not activated.")
        expect(current_path).to eq(project_settings_integrations_path(project))
      end

      it 'does not show the external tracker link in the menu' do
        page.within('.nav-sidebar') do
          expect(page).not_to have_link(tracker, href: url)
        end
      end
    end
  end

  it_behaves_like 'external issue tracker activation', tracker: 'Redmine'
  it_behaves_like 'external issue tracker activation', tracker: 'YouTrack', skip_new_issue_url: true
  it_behaves_like 'external issue tracker activation', tracker: 'Bugzilla'
  it_behaves_like 'external issue tracker activation', tracker: 'Custom Issue Tracker'
end
