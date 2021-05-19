# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User activates issue tracker', :js do
  include_context 'project service activation'

  let(:url) { 'http://tracker.example.com' }

  def fill_form(disable: false, skip_new_issue_url: false)
    click_active_checkbox if disable

    fill_in 'service_project_url', with: url
    fill_in 'service_issues_url', with: "#{url}/:id"

    fill_in 'service_new_issue_url', with: url unless skip_new_issue_url
  end

  shared_examples 'external issue tracker activation' do |tracker:, skip_new_issue_url: false, skip_test: false|
    describe 'user sets and activates the Service' do
      context 'when the connection test succeeds' do
        before do
          stub_request(:head, url).to_return(headers: { 'Content-Type' => 'application/json' })

          visit_project_integration(tracker)
          fill_form(skip_new_issue_url: skip_new_issue_url)

          if skip_test
            click_save_integration
          else
            click_test_then_save_integration(expect_test_to_fail: false)
          end
        end

        it 'activates the service' do
          expect(page).to have_content("#{tracker} settings saved and active.")
          expect(current_path).to eq(edit_project_service_path(project, tracker.parameterize(separator: '_')))
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

          if skip_test
            click_button('Save changes')
          else
            click_test_then_save_integration
          end

          expect(page).to have_content("#{tracker} settings saved and active.")
          expect(current_path).to eq(edit_project_service_path(project, tracker.parameterize(separator: '_')))
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
        expect(page).to have_content("#{tracker} settings saved, but not active.")
        expect(current_path).to eq(edit_project_service_path(project, tracker.parameterize(separator: '_')))
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
  it_behaves_like 'external issue tracker activation', tracker: 'Custom issue tracker'
  it_behaves_like 'external issue tracker activation', tracker: 'EWM', skip_test: true
end
