require 'spec_helper'

feature 'list of badges' do
  include Select2Helper

  background do
    user = create(:user)
    project = create(:project)
    project.team << [user, :master]
    login_as(user)
    visit edit_namespace_project_path(project.namespace, project)
  end

  scenario 'user displays list of badges' do
    click_link 'Badges'

    expect(page).to have_content 'build status'
    expect(page).to have_content 'Markdown'
    expect(page).to have_content 'HTML'
    expect(page).to have_css('.highlight', count: 2)
    expect(page).to have_xpath("//img[@alt='build status']")

    page.within('.highlight', match: :first) do
      expect(page).to have_content 'badges/master/build.svg'
    end
  end

  scenario 'user changes current ref on badges list page', js: true do
    click_link 'Badges'
    select2('improve/awesome', from: '#ref')

    expect(page).to have_content 'badges/improve/awesome/build.svg'
  end
end
