# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Template selector menu', :js, feature_category: :team_planning do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }

  before do
    project.add_maintainer(user)
    sign_in user
  end

  context 'editing a non-matching file' do
    before do
      visit project_edit_blob_path(project, File.join(project.default_branch, 'README.md'))
    end

    it 'is not displayed' do
      check_template_selector_menu_display(false)
    end

    context 'user toggles preview' do
      before do
        click_link 'Preview'
      end

      it 'template selector menu is not displayed' do
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

    it 'is displayed' do
      check_template_selector_menu_display(true)
    end

    context 'user toggles preview' do
      before do
        click_link 'Preview'
      end

      it 'template selector menu is hidden and shown correctly' do
        check_template_selector_menu_display(false)
        click_link 'Write'
        check_template_selector_menu_display(true)
      end
    end
  end
end

def check_template_selector_menu_display(is_visible)
  count = is_visible ? 1 : 0
  expect(page).to have_css('[data-testid="template-selector"]', count: count)
end
