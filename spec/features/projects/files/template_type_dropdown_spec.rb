require 'spec_helper'

feature 'Template type dropdown selector', :js do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }

  before do
    project.add_master(user)
    sign_in user
  end

  context 'editing a non-matching file' do
    before do
      create_and_edit_file('.random-file.js')
    end

    scenario 'not displayed' do
      check_type_selector_display(false)
    end

    scenario 'selects every template type correctly' do
      fill_in 'file_path', with: '.gitignore'
      try_selecting_all_types
    end

    scenario 'updates toggle value when input matches' do
      fill_in 'file_path', with: '.gitignore'
      check_type_selector_toggle_text('.gitignore')
    end
  end

  context 'editing a matching file' do
    before do
      visit project_edit_blob_path(project, File.join(project.default_branch, 'LICENSE'))
    end

    scenario 'displayed' do
      check_type_selector_display(true)
    end

    scenario 'is displayed when input matches' do
      check_type_selector_display(true)
    end

    scenario 'selects every template type correctly' do
      try_selecting_all_types
    end

    context 'user previews changes' do
      before do
        click_link 'Preview changes'
      end

      scenario 'type selector is hidden and shown correctly' do
        check_type_selector_display(false)
        click_link 'Write'
        check_type_selector_display(true)
      end
    end
  end

  context 'creating a matching file' do
    before do
      visit project_new_blob_path(project, 'master', file_name: '.gitignore')
    end

    scenario 'is displayed' do
      check_type_selector_display(true)
    end

    scenario 'toggle is set to the correct value' do
      check_type_selector_toggle_text('.gitignore')
    end

    scenario 'selects every template type correctly' do
      try_selecting_all_types
    end
  end

  context 'creating a file' do
    before do
      visit project_new_blob_path(project, project.default_branch)
    end

    scenario 'type selector is shown' do
      check_type_selector_display(true)
    end

    scenario 'toggle is set to the proper value' do
      check_type_selector_toggle_text('Choose type')
    end

    scenario 'selects every template type correctly' do
      try_selecting_all_types
    end
  end
end

def check_type_selector_display(is_visible)
  count = is_visible ? 1 : 0
  expect(page).to have_css('.js-template-type-selector', count: count)
end

def try_selecting_all_types
  try_selecting_template_type('LICENSE', 'Apply a license template')
  try_selecting_template_type('Dockerfile', 'Apply a Dockerfile template')
  try_selecting_template_type('.gitlab-ci.yml', 'Apply a GitLab CI Yaml template')
  try_selecting_template_type('.gitignore', 'Apply a .gitignore template')
end

def try_selecting_template_type(template_type, selector_label)
  select_template_type(template_type)
  check_template_selector_display(selector_label)
  check_type_selector_toggle_text(template_type)
end

def select_template_type(template_type)
  find('.js-template-type-selector').click
  find('.dropdown-content li', text: template_type).click
end

def check_template_selector_display(content)
  expect(page).to have_content(content)
end

def check_type_selector_toggle_text(template_type)
  dropdown_toggle_button = find('.template-type-selector .dropdown-toggle-text')
  expect(dropdown_toggle_button).to have_content(template_type)
end

def create_and_edit_file(file_name)
  visit project_new_blob_path(project, 'master', file_name: file_name)
  click_button "Commit changes"
  visit project_edit_blob_path(project, File.join(project.default_branch, file_name))
end
