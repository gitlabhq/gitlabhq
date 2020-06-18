# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Files > Template type dropdown selector', :js do
  let(:project) { create(:project, :repository) }
  let(:user) { project.owner }

  before do
    sign_in user
  end

  context 'editing a non-matching file' do
    before do
      create_and_edit_file('.random-file.js')
    end

    it 'not displayed' do
      check_type_selector_display(false)
    end

    it 'selects every template type correctly' do
      fill_in 'file_path', with: '.gitignore'
      try_selecting_all_types
    end

    it 'updates template type toggle value when template is chosen' do
      fill_in 'file_path', with: '.gitignore'
      select_template('gitignore', 'Actionscript')
      check_type_selector_toggle_text('.gitignore')
    end
  end

  context 'editing a matching file' do
    before do
      visit project_edit_blob_path(project, File.join(project.default_branch, 'LICENSE'))
    end

    it 'displayed' do
      check_type_selector_display(true)
    end

    it 'selects every template type correctly' do
      try_selecting_all_types
    end

    context 'user previews changes' do
      before do
        click_link 'Preview changes'
      end

      it 'type selector is hidden and shown correctly' do
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

    it 'is displayed' do
      check_type_selector_display(true)
    end

    it 'toggle is set to the correct value' do
      select_template('gitignore', 'Actionscript')
      check_type_selector_toggle_text('.gitignore')
    end

    it 'sets the toggle text when selecting the template type' do
      select_template_type('.gitignore')
      check_type_selector_toggle_text('.gitignore')
    end

    it 'selects every template type correctly' do
      try_selecting_all_types
    end
  end

  context 'creating a file' do
    before do
      visit project_new_blob_path(project, project.default_branch)
    end

    it 'type selector is shown' do
      check_type_selector_display(true)
    end

    it 'toggle is set to the proper value' do
      check_type_selector_toggle_text('Select a template type')
    end

    it 'selects every template type correctly' do
      try_selecting_all_types
    end
  end
end

def check_type_selector_display(is_visible)
  count = is_visible ? 1 : 0
  expect(page).to have_css('.js-template-type-selector', count: count)
end

def try_selecting_all_types
  try_selecting_template_type('LICENSE', 'Apply a template')
  try_selecting_template_type('Dockerfile', 'Apply a template')
  try_selecting_template_type('.gitlab-ci.yml', 'Apply a template')
  try_selecting_template_type('.gitignore', 'Apply a template')
end

def try_selecting_template_type(template_type, selector_label)
  select_template_type(template_type)
  check_template_selector_display(selector_label)
end

def select_template_type(template_type)
  find('.js-template-type-selector').click
  find('.dropdown-content li', text: template_type).click
end

def select_template(type, template)
  find(".js-#{type}-selector-wrap").click
  find('.dropdown-content li', text: template).click
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
