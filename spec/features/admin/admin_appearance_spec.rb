# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin Appearance', feature_category: :shared do
  let!(:appearance) { create(:appearance) }
  let(:admin) { create(:admin) }
  let(:user) { create(:user, name: 'John User') }
  let(:owner) { create(:user, name: 'John Admin') }
  let(:group) { create(:group) }
  let(:project) { create(:project, group: group) }

  before do
    stub_feature_flags(new_project_creation_form: false)
    stub_feature_flags(edit_user_profile_vue: false)
  end

  it 'create new appearance' do
    sign_in(admin)
    enable_admin_mode!(admin)
    visit admin_application_settings_appearances_path

    fill_in 'appearance_title', with: 'MyCompany'
    fill_in 'appearance_description', with: 'dev server'
    fill_in 'appearance_pwa_name', with: 'GitLab PWA'
    fill_in 'appearance_pwa_short_name', with: 'GitLab'
    fill_in 'appearance_pwa_description', with: 'GitLab as PWA'
    fill_in 'appearance_new_project_guidelines', with: 'Custom project guidelines'
    fill_in 'appearance_member_guidelines', with: 'Custom member guidelines'
    fill_in 'appearance_profile_image_guidelines', with: 'Custom profile image guidelines'
    click_button 'Update appearance settings'

    expect(page).to have_current_path admin_application_settings_appearances_path, ignore_query: true
    expect(page).to have_content 'Appearance'

    expect(page).to have_field('appearance_title', with: 'MyCompany')
    expect(page).to have_field('appearance_description', with: 'dev server')
    expect(page).to have_field('appearance_pwa_name', with: 'GitLab PWA')
    expect(page).to have_field('appearance_pwa_short_name', with: 'GitLab')
    expect(page).to have_field('appearance_pwa_description', with: 'GitLab as PWA')
    expect(page).to have_field('appearance_new_project_guidelines', with: 'Custom project guidelines')
    expect(page).to have_field('appearance_member_guidelines', with: 'Custom member guidelines')
    expect(page).to have_field('appearance_profile_image_guidelines', with: 'Custom profile image guidelines')
    expect(page).to have_content 'Last edit'
  end

  it 'preview sign-in page appearance' do
    sign_in(admin)
    enable_admin_mode!(admin)

    visit admin_application_settings_appearances_path
    click_link "Sign-in page"

    expect(find('#login')).to be_disabled
    expect(find('#password')).to be_disabled
    expect(find('button')).to be_disabled

    expect_custom_sign_in_appearance(appearance)
  end

  it 'preview new project page appearance', :js do
    sign_in(admin)
    enable_admin_mode!(admin)

    visit admin_application_settings_appearances_path
    click_link "New project page"

    expect_custom_new_project_appearance(appearance)
  end

  context 'Custom system header and footer' do
    before do
      sign_in(admin)
      enable_admin_mode!(admin)
    end

    context 'when system header and footer messages are empty' do
      it 'shows custom system header and footer fields' do
        visit admin_application_settings_appearances_path

        expect(page).to have_field('appearance_header_message', with: '')
        expect(page).to have_field('appearance_footer_message', with: '')
        expect(page).to have_field('appearance_message_background_color')
        expect(page).to have_field('appearance_message_font_color')
      end
    end

    context 'when system header and footer messages are not empty' do
      before do
        appearance.update!(header_message: 'Foo', footer_message: 'Bar')
      end

      it 'shows custom system header and footer fields' do
        visit admin_application_settings_appearances_path

        expect(page).to have_field('appearance_header_message', with: appearance.header_message)
        expect(page).to have_field('appearance_footer_message', with: appearance.footer_message)
        expect(page).to have_field('appearance_message_background_color')
        expect(page).to have_field('appearance_message_font_color')
      end
    end
  end

  it 'custom sign-in page' do
    visit new_user_session_path

    expect_custom_sign_in_appearance(appearance)
  end

  it 'custom new project page', :js do
    sign_in(admin)
    enable_admin_mode!(admin)
    visit new_project_path
    click_link 'Create blank project'

    expect_custom_new_project_appearance(appearance)
  end

  context 'Custom member guidelines' do
    before do
      sign_in(admin)
      enable_admin_mode!(admin)
      visit admin_application_settings_appearances_path
      fill_in 'appearance_member_guidelines', with: 'Custom member guidelines, please :smile:!'
      click_button 'Update appearance settings'
    end

    context 'on project member page' do
      before do
        project.add_owner(owner)
        project.add_developer(user)
      end

      it 'show for owners' do
        sign_in(owner)

        visit project_project_members_path(project)

        expect(page).to have_content 'Custom member guidelines, please 😄!'
      end

      it 'do not show for users' do
        sign_in(user)

        visit project_project_members_path(project)

        expect(page).not_to have_content 'Custom member guidelines, please 😄!'
      end
    end

    context 'on group member page' do
      before do
        group.add_owner(owner)
        group.add_developer(user)
      end

      it 'show for owners' do
        sign_in(owner)

        visit group_group_members_path(group)

        expect(page).to have_content 'Custom member guidelines, please 😄!'
      end

      it 'do not show for users' do
        sign_in(user)

        visit group_group_members_path(group)

        expect(page).not_to have_content 'Custom member guidelines, please 😄!'
      end
    end
  end

  context 'Profile page with custom profile image guidelines' do
    before do
      sign_in(admin)
      enable_admin_mode!(admin)
      visit admin_application_settings_appearances_path
      fill_in 'appearance_profile_image_guidelines', with: 'Custom profile image guidelines, please :smile:!'
      click_button 'Update appearance settings'
    end

    it 'renders guidelines when set' do
      sign_in create(:user)
      visit user_settings_profile_path

      expect(page).to have_content 'Custom profile image guidelines, please 😄!'
    end
  end

  it 'appearance logo' do
    sign_in(admin)
    enable_admin_mode!(admin)
    visit admin_application_settings_appearances_path

    attach_file(:appearance_logo, logo_fixture)
    click_button 'Update appearance settings'
    expect(page).to have_css(logo_selector)

    click_link 'Remove logo'
    expect(page).not_to have_css(logo_selector)
  end

  it 'appearance pwa icon' do
    sign_in(admin)
    enable_admin_mode!(admin)
    visit admin_application_settings_appearances_path

    attach_file(:appearance_pwa_icon, logo_fixture)
    click_button 'Update appearance settings'
    expect(page).to have_css(pwa_icon_selector)

    click_link 'Remove icon'
    expect(page).not_to have_css(pwa_icon_selector)
  end

  it 'header logos' do
    sign_in(admin)
    enable_admin_mode!(admin)
    visit admin_application_settings_appearances_path

    attach_file(:appearance_header_logo, logo_fixture)
    click_button 'Update appearance settings'
    expect(page).to have_css(header_logo_selector)

    click_link 'Remove header logo'
    expect(page).not_to have_css(header_logo_selector)
  end

  it 'Favicon' do
    sign_in(admin)
    enable_admin_mode!(admin)
    visit admin_application_settings_appearances_path

    attach_file(:appearance_favicon, logo_fixture)
    click_button 'Update appearance settings'

    expect(page).to have_css('.appearance-light-logo-preview')

    click_link 'Remove favicon'

    expect(page).not_to have_css('.appearance-light-logo-preview')

    # allowed file types
    attach_file(:appearance_favicon, Rails.root.join('spec', 'fixtures', 'sanitized.svg'))
    click_button 'Update appearance settings'

    expect(page).to have_content 'Favicon You are not allowed to upload "svg" files, allowed types: png, ico'
  end

  def expect_custom_sign_in_appearance(appearance)
    expect(page).to have_content appearance.title
    expect(page).to have_content appearance.description
  end

  def expect_custom_new_project_appearance(appearance)
    expect(page).to have_content appearance.new_project_guidelines
  end

  def logo_selector
    '//img[data-src^="/uploads/-/system/appearance/logo"]'
  end

  def pwa_icon_selector
    '//img[data-src^="/uploads/-/system/appearance/pwa_icon"]'
  end

  def header_logo_selector
    '//img[data-src^="/uploads/-/system/appearance/header_logo"]'
  end

  def logo_fixture
    Rails.root.join('spec', 'fixtures', 'dk.png')
  end
end
