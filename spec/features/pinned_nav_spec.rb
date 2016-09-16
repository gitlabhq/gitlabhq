require 'spec_helper'

feature 'Pinned nav', feature: true, js: true do
  before do
    login_as(:admin)
    show_nav
  end

  it 'hides pinned nav on resize' do
    page.driver.resize_window(1000, 768)

    expect(page).not_to have_selector('.page-sidebar-pinned')
  end

  it 'shows pinned nav after resize' do
    page.driver.resize_window(1000, 768)

    expect(page).not_to have_selector('.page-sidebar-pinned')

    page.driver.resize_window(1024, 768)

    expect(page).to have_selector('.page-sidebar-pinned')
  end

  def show_nav
    find('.side-nav-toggle').click
    expect(page).to have_selector('.page-sidebar-expanded')

    find('.js-nav-pin').click
    expect(page).to have_selector('.page-sidebar-pinned')
  end
end
