# frozen_string_literal: true

require 'spec_helper'

describe 'Showing instance statistics' do
  before do
    sign_in user if user
  end

  # Using a path that is publicly accessible
  subject { visit explore_projects_path }

  context 'for unauthenticated users' do
    let(:user) { nil }

    it 'does not show the instance statistics link' do
      subject

      expect(page).not_to have_link('Instance Statistics')
    end
  end

  context 'for regular users' do
    let(:user) { create(:user) }

    context 'when instance statistics are publicly available' do
      before do
        stub_application_setting(instance_statistics_visibility_private: false)
      end

      it 'shows the instance statistics link' do
        subject

        expect(page).to have_link('Instance Statistics')
      end
    end

    context 'when instance statistics are not publicly available' do
      before do
        stub_application_setting(instance_statistics_visibility_private: true)
      end

      it 'shows the instance statistics link' do
        subject

        expect(page).not_to have_link('Instance Statistics')
      end
    end
  end

  context 'for admins' do
    let(:user) { create(:admin) }

    it 'shows the instance statistics link' do
      subject

      expect(page).to have_link('Instance Statistics')
    end
  end
end
