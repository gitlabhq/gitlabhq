require 'spec_helper'

feature 'Template selector menu', :js do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }

  before do
    project.add_master(user)
    sign_in user
  end

  context 'editing a non-matching file' do
    before do
      create_and_edit_file('README.md')
    end

    scenario 'is not displayed' do
      check_template_selector_menu_display(false)
    end

    context 'user toggles preview' do
      before do
        click_link 'Preview'
      end

      scenario 'template selector menu is not displayed' do
        check_template_selector_menu_display(false)
        click_link 'Write'
        check_template_selector_menu_display(false)
      end
    end
  end

  context 'editing a matching file' do
    before do
      visit project_edit_blob_path(project, File.join(project.default_branch, 'LICENSE'))
    end

    scenario 'is displayed' do
      check_template_selector_menu_display(true)
    end

    context 'user toggles preview' do
      before do
        click_link 'Preview'
      end

      scenario 'template selector menu is hidden and shown correctly' do
        check_template_selector_menu_display(false)
        click_link 'Write'
        check_template_selector_menu_display(true)
      end
    end
  end
end

def check_template_selector_menu_display(is_visible)
  count = is_visible ? 1 : 0
  expect(page).to have_css('.template-selectors-menu', count: count)
end

def create_and_edit_file(file_name)
  visit project_new_blob_path(project, 'master', file_name: file_name)
  click_button "Commit changes"
  visit project_edit_blob_path(project, File.join(project.default_branch, file_name))
end
