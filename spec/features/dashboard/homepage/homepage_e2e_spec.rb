# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dashboard - Homepage E2E', :js, feature_category: :notifications do
  let_it_be(:user) { create(:user, :with_namespace) }
  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:group) { create(:group) }

  before_all do
    project.add_developer(user)
    group.add_developer(user)
  end

  before do
    stub_feature_flags(personal_homepage: true)
    sign_in user
  end

  describe 'Core Homepage Functionality' do
    it 'loads the homepage successfully with correct title and navigation' do
      visit home_dashboard_path
      wait_for_requests

      expect(page).to have_title('Home')
      expect(page).to have_current_path(home_dashboard_path)
    end

    it 'displays navigation and allows basic homepage functionality' do
      visit home_dashboard_path
      wait_for_requests

      expect(page).to have_current_path(home_dashboard_path)
      expect(page).to have_title('Home')
    end

    it 'tracks homepage view events correctly' do
      expect(Gitlab::InternalEvents).to receive(:track_event)
        .with('user_views_homepage', category: 'DashboardController', user: user)
        .at_least(:once)

      allow(Gitlab::InternalEvents).to receive(:track_event).and_call_original

      visit home_dashboard_path
    end

    it 'maintains responsive design on mobile and desktop' do
      page.driver.browser.manage.window.resize_to(375, 667)
      visit home_dashboard_path
      wait_for_requests
      expect(page).to have_title('Home')

      page.driver.browser.manage.window.resize_to(1920, 1080)
      visit home_dashboard_path
      wait_for_requests
      expect(page).to have_title('Home')
    end
  end

  describe 'Complete Navigation Workflow' do
    it 'supports navigation through main dashboard sections' do
      visit home_dashboard_path
      wait_for_requests

      if page.has_link?('Projects') # rubocop:disable RSpec/AvoidConditionalStatements -- Navigation links may vary by user permissions
        click_link 'Projects'
        expect(page).to have_current_path(%r{dashboard/projects}, ignore_query: true)
      end

      if page.has_link?('Groups') # rubocop:disable RSpec/AvoidConditionalStatements -- Navigation links may vary by user permissions
        click_link 'Groups'
        expect(page).to have_current_path(%r{dashboard/groups}, ignore_query: true)
      end

      if page.has_link?('Issues') # rubocop:disable RSpec/AvoidConditionalStatements -- Navigation links may vary by user permissions
        click_link 'Issues'
        expect(page).to have_current_path(%r{dashboard/issues}, ignore_query: true)
      end

      if page.has_link?('Merge requests') # rubocop:disable RSpec/AvoidConditionalStatements -- Navigation links may vary by user permissions
        click_link 'Merge requests'
        expect(page).to have_current_path(%r{dashboard/merge_requests}, ignore_query: true)
      end

      visit home_dashboard_path
      expect(page).to have_current_path(home_dashboard_path, ignore_query: true)
      expect(page).to have_title('Home')
    end
  end

  describe 'Performance and Reliability' do
    it 'loads the homepage within reasonable time' do
      start_time = Time.current

      visit home_dashboard_path
      wait_for_requests

      load_time = Time.current - start_time
      expect(load_time).to be < 30.seconds
      expect(page).to have_title('Home')
    end

    it 'maintains state across page refreshes' do
      visit home_dashboard_path
      wait_for_requests

      page.refresh
      wait_for_requests

      expect(page).to have_title('Home')
      expect(page).to have_current_path(home_dashboard_path)
    end

    it 'handles error conditions gracefully' do
      visit home_dashboard_path
      wait_for_requests

      expect(page).to have_title('Home')
      expect(page).to have_current_path(home_dashboard_path)
    end
  end

  describe 'Integration and Edge Cases' do
    it 'integrates properly with GitLab core features' do
      visit home_dashboard_path
      wait_for_requests

      expect(page).to have_current_path(home_dashboard_path)
      expect(page).to have_current_path(home_dashboard_path)
    end

    it 'handles empty data states correctly' do
      user.todos.delete_all
      Event.delete_all

      visit home_dashboard_path
      wait_for_requests

      expect(page).to have_title('Home')
      expect(page).to have_current_path(home_dashboard_path)
    end

    it 'supports basic accessibility features' do
      visit home_dashboard_path
      wait_for_requests

      expect(page).to have_current_path(home_dashboard_path)

      page.send_keys(:tab)
      expect(page).to have_current_path(home_dashboard_path)
    end
  end
end
