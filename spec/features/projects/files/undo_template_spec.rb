require 'spec_helper'

feature 'Template Undo Button', :js do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }

  before do
    project.add_master(user)
    sign_in user
  end

  context 'editing a matching file and applying a template' do
    before do
      visit project_edit_blob_path(project, File.join(project.default_branch, "LICENSE"))
      select_file_template('.js-license-selector', 'Apache License 2.0')
    end

    scenario 'reverts template application' do
      try_template_undo('http://www.apache.org/licenses/', 'Apply a license template')
    end
  end

  context 'creating a non-matching file' do
    before do
      visit project_new_blob_path(project, 'master')
      select_file_template_type('LICENSE')
      select_file_template('.js-license-selector', 'Apache License 2.0')
    end

    scenario 'reverts template application' do
      try_template_undo('http://www.apache.org/licenses/', 'Apply a license template')
    end
  end
end

def try_template_undo(template_content, toggle_text)
  check_undo_button_display
  check_content_reverted(template_content)
  check_toggle_text_set(toggle_text)
end

def check_toggle_text_set(neutral_toggle_text)
  expect(page).to have_content(neutral_toggle_text)
end

def check_undo_button_display
  expect(page).to have_content('Template applied')
  expect(page).to have_css('.template-selectors-undo-menu .btn-info')
end

def check_content_reverted(template_content)
  find('.template-selectors-undo-menu .btn-info').click
  expect(page).not_to have_content(template_content)
  expect(find('.template-type-selector .dropdown-toggle-text')).to have_content()
end

def select_file_template(template_selector_selector, template_name)
  find(template_selector_selector).click
  find('.dropdown-content li', text: template_name).click
  wait_for_requests
end

def select_file_template_type(template_type)
  find('.js-template-type-selector').click
  find('.dropdown-content li', text: template_type).click
end
