require 'spec_helper'

feature 'list of badges' do
  background do
    user = create(:user)
    project = create(:project, :repository)
    project.add_master(user)
    sign_in(user)
    visit project_settings_ci_cd_path(project)
  end

  scenario 'user wants to see build status badge' do
    page.within('.pipeline-status') do
      expect(page).to have_content 'pipeline status'
      expect(page).to have_content 'Markdown'
      expect(page).to have_content 'HTML'
      expect(page).to have_content 'AsciiDoc'
      expect(page).to have_css('.highlight', count: 3)
      expect(page).to have_xpath("//img[@alt='pipeline status']")

      page.within('.highlight', match: :first) do
        expect(page).to have_content 'badges/master/pipeline.svg'
      end
    end
  end

  scenario 'user wants to see coverage report badge' do
    page.within('.coverage-report') do
      expect(page).to have_content 'coverage report'
      expect(page).to have_content 'Markdown'
      expect(page).to have_content 'HTML'
      expect(page).to have_content 'AsciiDoc'
      expect(page).to have_css('.highlight', count: 3)
      expect(page).to have_xpath("//img[@alt='coverage report']")

      page.within('.highlight', match: :first) do
        expect(page).to have_content 'badges/master/coverage.svg'
      end
    end
  end

  scenario 'user changes current ref of build status badge', :js do
    page.within('.pipeline-status') do
      first('.js-project-refs-dropdown').click

      page.within '.project-refs-form' do
        click_link 'improve/awesome'
      end

      expect(page).to have_content 'badges/improve/awesome/pipeline.svg'
    end
  end
end
