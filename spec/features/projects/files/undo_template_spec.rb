# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Files > Template Undo Button', :js, feature_category: :team_planning do
  let(:project) { create(:project, :repository) }
  let(:user) { project.first_owner }

  before do
    sign_in user
  end

  context 'editing a matching file and applying a template' do
    before do
      visit project_edit_blob_path(project, File.join(project.default_branch, "LICENSE"))
      select_file_template('Apache License 2.0')
    end

    it 'reverts template application' do
      try_template_undo('http://www.apache.org/licenses/', 'Apply a template')
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
  expect(page).to have_content('template applied')
  expect(page).to have_css('.b-toaster')
end

def check_content_reverted(template_content)
  find('.b-toaster a', text: 'Undo').click
  expect(page).not_to have_content(template_content)
end

def select_file_template(template_name)
  click_button 'Apply a template'
  find('.gl-new-dropdown-contents li', text: template_name).click
  wait_for_requests
end
