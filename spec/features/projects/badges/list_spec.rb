# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'list of badges', feature_category: :continuous_integration do
  before do
    user = create(:user)
    project = create(:project, :repository)
    project.add_maintainer(user)
    sign_in(user)
    visit project_settings_ci_cd_path(project)
  end

  it 'user wants to see build status badge' do
    page.within('.pipeline-status') do
      expect(page).to have_content 'pipeline status'
      expect(page).to have_content 'Markdown'
      expect(page).to have_content 'HTML'
      expect(page).to have_content 'AsciiDoc'
      expect(page).to have_css('.js-syntax-highlight', count: 3)
      expect(page).to have_xpath("//img[@alt='pipeline status']")

      page.within('.js-syntax-highlight', match: :first) do
        expect(page).to have_content 'badges/master/pipeline.svg'
      end
    end
  end

  it 'user wants to see coverage report badge' do
    page.within('.coverage-report') do
      expect(page).to have_content 'coverage report'
      expect(page).to have_content 'Markdown'
      expect(page).to have_content 'HTML'
      expect(page).to have_content 'AsciiDoc'
      expect(page).to have_css('.js-syntax-highlight', count: 3)
      expect(page).to have_xpath("//img[@alt='coverage report']")

      page.within('.js-syntax-highlight', match: :first) do
        expect(page).to have_content 'badges/master/coverage.svg'
      end
    end
  end

  it 'user changes current ref of build status badge', :js do
    page.within('.pipeline-status') do
      find('.ref-selector').click
      wait_for_requests

      page.within('.ref-selector') do
        fill_in 'Search by Git revision', with: 'improve/awesome'
        wait_for_requests
        find('li', text: 'improve/awesome', match: :prefer_exact).click
      end

      expect(page).to have_content 'badges/improve/awesome/pipeline.svg'
    end
  end

  it 'user changes current ref of coverage status badge', :js do
    page.within('.coverage-report') do
      find('.ref-selector').click
      wait_for_requests

      page.within('.ref-selector') do
        fill_in 'Search by Git revision', with: 'improve/awesome'
        wait_for_requests
        find('li', text: 'improve/awesome', match: :prefer_exact).click
      end

      expect(page).to have_content 'badges/improve/awesome/coverage.svg'
    end
  end

  it 'user changes current ref of latest release status badge', :js do
    page.within('.Latest-Release') do
      find('.ref-selector').click
      wait_for_requests

      page.within('.ref-selector') do
        fill_in 'Search by Git revision', with: 'improve/awesome'
        wait_for_requests
        find('li', text: 'improve/awesome', match: :prefer_exact).click
      end

      expect(page).to have_content '-/badges/release.svg'
    end
  end
end
