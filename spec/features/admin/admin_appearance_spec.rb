require 'spec_helper'

feature 'Admin Appearance' do
  let!(:appearance) { create(:appearance) }

  scenario 'Create new appearance' do
    sign_in(create(:admin))
    visit admin_appearances_path

    fill_in 'appearance_title', with: 'MyCompany'
    fill_in 'appearance_description', with: 'dev server'
    click_button 'Save'

    expect(current_path).to eq admin_appearances_path
    expect(page).to have_content 'Appearance settings'

    expect(page).to have_field('appearance_title', with: 'MyCompany')
    expect(page).to have_field('appearance_description', with: 'dev server')
    expect(page).to have_content 'Last edit'
  end

  scenario 'Preview appearance' do
    sign_in(create(:admin))

    visit admin_appearances_path
    click_link "Preview"

    expect_page_has_custom_appearance(appearance)
  end

  scenario 'Custom sign-in page' do
    visit new_user_session_path
    expect_page_has_custom_appearance(appearance)
  end

  scenario 'Appearance logo' do
    sign_in(create(:admin))
    visit admin_appearances_path

    attach_file(:appearance_logo, logo_fixture)
    click_button 'Save'
    expect(page).to have_css(logo_selector)

    click_link 'Remove logo'
    expect(page).not_to have_css(logo_selector)
  end

  scenario 'Header logos' do
    sign_in(create(:admin))
    visit admin_appearances_path

    attach_file(:appearance_header_logo, logo_fixture)
    click_button 'Save'
    expect(page).to have_css(header_logo_selector)

    click_link 'Remove header logo'
    expect(page).not_to have_css(header_logo_selector)
  end

  def expect_page_has_custom_appearance(appearance)
    expect(page).to have_content appearance.title
    expect(page).to have_content appearance.description
  end

  def logo_selector
    '//img[data-src^="/uploads/-/system/appearance/logo"]'
  end

  def header_logo_selector
    '//img[data-src^="/uploads/-/system/appearance/header_logo"]'
  end

  def logo_fixture
    Rails.root.join('spec', 'fixtures', 'dk.png')
  end
end
