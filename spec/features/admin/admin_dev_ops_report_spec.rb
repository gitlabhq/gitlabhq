# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'DevOps Report page', :js do
  before do
    admin = create(:admin)
    sign_in(admin)
    gitlab_enable_admin_mode_sign_in(admin)
  end

  context 'with devops_adoption feature flag disabled' do
    before do
      stub_feature_flags(devops_adoption: false)
    end

    it 'has dismissable intro callout' do
      visit admin_dev_ops_report_path

      expect(page).to have_content 'Introducing Your DevOps Report'

      find('.js-close-callout').click

      expect(page).not_to have_content 'Introducing Your DevOps Report'
    end

    context 'when usage ping is disabled' do
      before do
        stub_application_setting(usage_ping_enabled: false)
      end

      it 'shows empty state' do
        visit admin_dev_ops_report_path

        expect(page).to have_selector(".js-empty-state")
      end

      it 'hides the intro callout' do
        visit admin_dev_ops_report_path

        expect(page).not_to have_content 'Introducing Your DevOps Report'
      end
    end

    context 'when there is no data to display' do
      it 'shows empty state' do
        stub_application_setting(usage_ping_enabled: true)

        visit admin_dev_ops_report_path

        expect(page).to have_content('Data is still calculating')
      end
    end

    context 'when there is data to display' do
      it 'shows numbers for each metric' do
        stub_application_setting(usage_ping_enabled: true)
        create(:dev_ops_report_metric)

        visit admin_dev_ops_report_path

        expect(page).to have_content(
          'Issues created per active user 1.2 You 9.3 Lead 13.3%'
        )
      end
    end
  end
end
