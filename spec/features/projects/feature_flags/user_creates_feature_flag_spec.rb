# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User creates feature flag', :js do
  include FeatureFlagHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, namespace: user.namespace) }
  let!(:environment) { create(:environment, :production, project: project) }

  before do
    project.add_developer(user)
    sign_in(user)
  end

  it 'user creates a flag enabled for user ids with existing environment' do
    visit(new_project_feature_flag_path(project))
    set_feature_flag_info('test_feature', 'Test feature')
    within_strategy_row(1) do
      select 'User IDs', from: 'Type'
      fill_in 'User IDs', with: 'user1, user2'
      environment_plus_button.click
      environment_search_input.set('production')
      environment_search_results.first.click
    end
    click_button 'Create feature flag'

    expect_user_to_see_feature_flags_index_page
    expect(page).to have_text('test_feature')
  end

  it 'user creates a flag enabled for user ids with non-existing environment' do
    visit(new_project_feature_flag_path(project))
    set_feature_flag_info('test_feature', 'Test feature')
    within_strategy_row(1) do
      select 'User IDs', from: 'Type'
      fill_in 'User IDs', with: 'user1, user2'
      environment_plus_button.click
      environment_search_input.set('foo-bar')
      environment_search_create_button.first.click
    end
    click_button 'Create feature flag'

    expect_user_to_see_feature_flags_index_page
    expect(page).to have_text('test_feature')
  end

  it 'user creates a flag with default environment scopes' do
    visit(new_project_feature_flag_path(project))
    set_feature_flag_info('test_flag', 'Test flag')
    within_strategy_row(1) do
      select 'All users', from: 'Type'
    end
    click_button 'Create feature flag'

    expect_user_to_see_feature_flags_index_page
    expect(page).to have_text('test_flag')

    edit_feature_flag_button.click

    within_strategy_row(1) do
      expect(page).to have_text('All users')
      expect(page).to have_text('All environments')
    end
  end

  it 'removes the correct strategy when a strategy is deleted' do
    visit(new_project_feature_flag_path(project))
    click_button 'Add strategy'
    within_strategy_row(1) do
      select 'All users', from: 'Type'
    end
    within_strategy_row(2) do
      select 'Percent of users', from: 'Type'
    end
    within_strategy_row(1) do
      delete_strategy_button.click
    end

    within_strategy_row(1) do
      expect(page).to have_select('Type', selected: 'Percent of users')
    end
  end

  private

  def set_feature_flag_info(name, description)
    fill_in 'Name', with: name
    fill_in 'Description', with: description
  end

  def environment_plus_button
    find('[data-testid=new-environments-dropdown]')
  end

  def environment_search_input
    find('[data-testid=new-environments-dropdown] input')
  end

  def environment_search_results
    all('[data-testid=new-environments-dropdown] li')
  end

  def environment_search_create_button
    all('[data-testid=new-environments-dropdown] button')
  end
end
