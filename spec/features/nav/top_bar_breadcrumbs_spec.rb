# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Top bar breadcrumbs', :js, feature_category: :navigation do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, maintainers: user) }

  before do
    sign_in(user)
  end

  it 'shows the static breadcrumbs' do
    visit project_path(project)

    within_testid('breadcrumb-links') do
      expect(page).to have_css('nav[aria-label="Breadcrumb"]', count: 1, text: project.name)
      expect(page).to have_link(project.name, href: project_path(project))
    end
  end

  it 'replaces the static breadcrumbs with the ones a page injects' do
    visit project_packages_path(project)

    within_testid('breadcrumb-links') do
      expect(page).to have_css('nav[aria-label="Breadcrumb"]', text: 'Package registry')
      expect(page).to have_css('nav[aria-label="Breadcrumb"]', count: 1)
    end
  end
end
