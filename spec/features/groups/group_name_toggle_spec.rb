require 'spec_helper'

feature 'Group name toggle', feature: true, js: true do
  let(:group) { create(:group) }
  let(:nested_group_1) { create(:group, parent: group) }
  let(:nested_group_2) { create(:group, parent: nested_group_1) }
  let(:nested_group_3) { create(:group, parent: nested_group_2) }

  SMALL_SCREEN = 300

  before do
    sign_in(create(:user))
  end

  it 'is not present if enough horizontal space' do
    visit group_path(nested_group_3)

    container_width = page.evaluate_script("$('.title-container')[0].offsetWidth")
    title_width = page.evaluate_script("$('.title')[0].offsetWidth")

    expect(container_width).to be > title_width
    expect(page).not_to have_css('.group-name-toggle')
  end

  it 'is present if the title is longer than the container', :nested_groups do
    visit group_path(nested_group_3)
    title_width = page.evaluate_script("$('.title')[0].offsetWidth")

    page_height = page.current_window.size[1]
    page.current_window.resize_to(SMALL_SCREEN, page_height)

    find('.group-name-toggle')
    container_width = page.evaluate_script("$('.title-container')[0].offsetWidth")

    expect(title_width).to be > container_width
  end

  it 'should show the full group namespace when toggled', :nested_groups do
    page_height = page.current_window.size[1]
    page.current_window.resize_to(SMALL_SCREEN, page_height)
    visit group_path(nested_group_3)

    expect(page).not_to have_content(group.name)
    expect(page).to have_css('.group-path.hidable', visible: false)

    click_button '...'

    expect(page).to have_content(group.name)
    expect(page).to have_css('.group-path.hidable', visible: true)
  end
end
