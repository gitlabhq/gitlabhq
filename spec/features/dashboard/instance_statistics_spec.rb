# frozen_string_literal: true

require 'spec_helper'

describe 'Showing analytics' do
  before do
    sign_in user if user
  end

  # Using a path that is publicly accessible
  subject { visit explore_projects_path }

  context 'for unauthenticated users' do
    let(:user) { nil }

    it 'does not show the Analytics link' do
      subject

      expect(page).not_to have_link('Analytics')
    end
  end

  context 'for regular users' do
    let(:user) { create(:user) }

    context 'when instance statistics are publicly available' do
      before do
        stub_application_setting(instance_statistics_visibility_private: false)
      end

      it 'shows the analytics link' do
        subject

        expect(page).to have_link('Analytics')
      end
    end

    context 'when instance statistics are not publicly available' do
      before do
        stub_application_setting(instance_statistics_visibility_private: true)
      end

      it 'does not show the analytics link' do
        subject

        # Skipping this test on EE as there is an EE specifc spec for this functionality
        # ee/spec/features/dashboards/analytics_spec.rb
        skip if Gitlab.ee?

        expect(page).not_to have_link('Analytics')
      end
    end
  end

  context 'for admins' do
    let(:user) { create(:admin) }

    it 'shows the analytics link' do
      subject

      expect(page).to have_link('Analytics')
    end
  end
end
