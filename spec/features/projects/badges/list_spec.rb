require 'spec_helper'

feature 'list of badges' do
  background do
    user = create(:user)
    project = create(:project)
    project.team << [user, :master]
    login_as(user)
    visit namespace_project_pipelines_settings_path(project.namespace, project)
  end

  scenario 'user wants to see build status badge' do
    page.within('.build-status') do
      expect(page).to have_content 'build status'
      expect(page).to have_content 'Markdown'
      expect(page).to have_content 'HTML'
      expect(page).to have_css('.highlight', count: 2)
      expect(page).to have_xpath("//img[@alt='build status']")

      page.within('.highlight', match: :first) do
        expect(page).to have_content 'badges/master/build.svg'
      end
    end
  end

  scenario 'user wants to see coverage report badge' do
    page.within('.coverage-report') do
      expect(page).to have_content 'coverage report'
      expect(page).to have_content 'Markdown'
      expect(page).to have_content 'HTML'
      expect(page).to have_css('.highlight', count: 2)
      expect(page).to have_xpath("//img[@alt='coverage report']")

      page.within('.highlight', match: :first) do
        expect(page).to have_content 'badges/master/coverage.svg'
      end
    end
  end

  scenario 'user changes current ref of build status badge', js: true do
    page.within('.build-status') do
      first('.js-project-refs-dropdown').click

      page.within '.project-refs-form' do
        click_link 'improve/awesome'
      end

      expect(page).to have_content 'badges/improve/awesome/build.svg'
    end
  end
end
