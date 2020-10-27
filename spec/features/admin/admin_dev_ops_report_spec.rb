# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'DevOps Report page', :js do
  tabs_selector = '.js-devops-tabs'
  tab_item_selector = '.js-devops-tab-item'
  active_tab_selector = '.nav-link.active'

  before do
    sign_in(create(:admin))
  end

  context 'with devops_adoption feature flag disabled' do
    before do
      stub_feature_flags(devops_adoption: false)
    end

    it 'does not show the tabbed layout' do
      visit admin_dev_ops_report_path

      expect(page).not_to have_selector tabs_selector
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

  context 'with devops_adoption feature flag enabled' do
    it 'shows the tabbed layout' do
      visit admin_dev_ops_report_path

      expect(page).to have_selector tabs_selector
    end

    it 'shows the correct tabs' do
      visit admin_dev_ops_report_path

      within tabs_selector do
        expect(page.all(:css, tab_item_selector).length).to be(2)
        expect(page).to have_text 'DevOps Score Adoption'
      end
    end

    it 'defaults to the DevOps Score tab' do
      visit admin_dev_ops_report_path

      within tabs_selector do
        expect(page).to have_selector active_tab_selector, text: 'DevOps Score'
      end
    end

    it 'displays the Adoption tab content when selected' do
      visit admin_dev_ops_report_path

      click_link 'Adoption'

      within tabs_selector do
        expect(page).to have_selector active_tab_selector, text: 'Adoption'
      end
    end

    context 'the devops score tab' do
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
end
