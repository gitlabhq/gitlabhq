# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User deletes feature flag user list', :js do
  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user) }

  before do
    project.add_developer(developer)
    sign_in(developer)
  end

  context 'with a list' do
    before do
      create(:operations_feature_flag_user_list, project: project, name: 'My List')
    end

    it 'deletes the list' do
      visit(project_feature_flags_user_lists_path(project, scope: 'userLists'))

      delete_user_list_button.click
      delete_user_list_modal_confirmation_button.click

      expect(page).to have_text('Lists')
      expect(page).not_to have_selector('[data-testid="ffUserListName"]')
    end
  end

  context 'with a list that is in use' do
    before do
      list = create(:operations_feature_flag_user_list, project: project, name: 'My List')
      feature_flag = create(:operations_feature_flag, :new_version_flag, project: project)
      create(:operations_strategy, feature_flag: feature_flag, name: 'gitlabUserList', user_list: list)
    end

    it 'does not delete the list' do
      visit(project_feature_flags_user_lists_path(project, scope: 'userLists'))

      delete_user_list_button.click
      delete_user_list_modal_confirmation_button.click

      expect(page).to have_text('User list is associated with a strategy')
      expect(page).to have_text('Lists 1')
      expect(page).to have_text('My List')

      alert_dismiss_button.click

      expect(page).not_to have_text('User list is associated with a strategy')
    end
  end

  def delete_user_list_button
    find("button[data-testid='delete-user-list']")
  end

  def delete_user_list_modal_confirmation_button
    find("button[data-testid='modal-confirm']")
  end

  def alert_dismiss_button
    find("div[data-testid='serverErrors'] button")
  end
end
