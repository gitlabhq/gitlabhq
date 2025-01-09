# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Secure Files', :js, feature_category: :secrets_management do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  context 'when disabled at the instance level' do
    before do
      stub_config(ci_secure_files: { enabled: false })
    end

    it 'does not show the secure files settings' do
      visit project_settings_ci_cd_path(project)
      expect(page).not_to have_content('Secure files')
    end
  end

  context 'authenticated user with admin permissions' do
    it 'shows the secure files settings' do
      visit project_settings_ci_cd_path(project)
      expect(page).to have_content('Secure files')
    end
  end

  it 'user sees the Secure Files list component' do
    visit project_settings_ci_cd_path(project)

    within '#js-secure-files' do
      expect(page).to have_content('There are no secure files yet.')
    end
  end

  it 'prompts the user to confirm before deleting a file' do
    file = create(:ci_secure_file, project: project)

    visit project_settings_ci_cd_path(project)

    within '#js-secure-files' do
      expect(page).to have_content(file.name)

      find_by_testid('delete-button').click
    end

    expect(page).to have_content("Delete #{file.name}?")

    click_on('Delete secure file')

    visit project_settings_ci_cd_path(project)

    within '#js-secure-files' do
      expect(page).not_to have_content(file.name)
    end
  end

  it 'displays an uploaded file in the file list' do
    visit project_settings_ci_cd_path(project)

    within '#js-secure-files' do
      expect(page).to have_content('There are no secure files yet.')

      page.attach_file('spec/fixtures/ci_secure_files/upload-keystore.jks') do
        click_button 'Upload File'
      end

      expect(page).to have_content('upload-keystore.jks')
    end
  end

  it 'displays an error when a duplicate file upload is attempted' do
    create(:ci_secure_file, project: project, name: 'upload-keystore.jks')
    visit project_settings_ci_cd_path(project)

    within '#js-secure-files' do
      expect(page).to have_content('upload-keystore.jks')

      page.attach_file('spec/fixtures/ci_secure_files/upload-keystore.jks') do
        click_button 'Upload File'
      end

      expect(page).to have_content('A file with this name already exists.')
    end
  end
end
