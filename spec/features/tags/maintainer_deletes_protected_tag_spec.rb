# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Maintainer deletes protected tag', :js, feature_category: :source_code_management do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:project) { create(:project, :repository, namespace: group) }
  let(:tag_name) { 'v1.1.1' }

  before do
    project.add_maintainer(user)
    sign_in(user)
    create(:protected_tag, project: project, name: tag_name)
    visit project_tags_path(project)
  end

  context 'from the tags list page' do
    it 'deletes the tag' do
      expect(page).to have_content "#{tag_name} protected"

      within_testid('tag-row', text: tag_name) do
        click_button('Delete tag')
      end

      assert_modal_content(tag_name)
      confirm_delete_tag(tag_name)

      expect(page).not_to have_content tag_name
    end
  end

  context 'from a specific tag page' do
    before do
      click_on tag_name
    end

    it 'deletes the tag' do
      expect(page).to have_current_path(project_tag_path(project, tag_name), ignore_query: true)

      click_button('Delete tag')
      assert_modal_content(tag_name)
      confirm_delete_tag(tag_name)

      expect(page).to have_current_path(project_tags_path(project), ignore_query: true)
      expect(page).not_to have_content tag_name
    end
  end

  def assert_modal_content(tag_name)
    within '.modal' do
      expect(page).to have_content("Please type the following to confirm: #{tag_name}")
      expect(page).to have_field('delete_tag_input')
      expect(page).to have_button('Yes, delete protected tag', disabled: true)
    end
  end

  def confirm_delete_tag(tag_name)
    within '.modal' do
      fill_in('delete_tag_input', with: tag_name)
      click_button('Yes, delete protected tag')
      wait_for_requests
    end
  end
end
