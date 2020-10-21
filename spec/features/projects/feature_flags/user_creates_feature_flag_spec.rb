# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User creates feature flag', :js do
  include FeatureFlagHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, namespace: user.namespace) }

  before do
    project.add_developer(user)
    stub_feature_flags(feature_flag_permissions: false)
    sign_in(user)
  end

  it 'user creates a flag enabled for user ids' do
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

  context 'with new version flags disabled' do
    before do
      stub_feature_flags(feature_flags_new_version: false)
    end

    context 'when creates without changing scopes' do
      before do
        visit(new_project_feature_flag_path(project))
        set_feature_flag_info('ci_live_trace', 'For live trace')
        click_button 'Create feature flag'
        expect(page).to have_current_path(project_feature_flags_path(project))
      end

      it 'shows the created feature flag' do
        within_feature_flag_row(1) do
          expect(page.find('.feature-flag-name')).to have_content('ci_live_trace')
          expect_status_toggle_button_to_be_checked

          within_feature_flag_scopes do
            expect(page.find('[data-qa-selector="feature-flag-scope-info-badge"]:nth-child(1)')).to have_content('*')
          end
        end
      end
    end

    context 'when creates with disabling the default scope' do
      before do
        visit(new_project_feature_flag_path(project))
        set_feature_flag_info('ci_live_trace', 'For live trace')

        within_scope_row(1) do
          within_status { find('.project-feature-toggle').click }
        end

        click_button 'Create feature flag'
      end

      it 'shows the created feature flag' do
        within_feature_flag_row(1) do
          expect(page.find('.feature-flag-name')).to have_content('ci_live_trace')
          expect_status_toggle_button_to_be_checked

          within_feature_flag_scopes do
            expect(page.find('[data-qa-selector="feature-flag-scope-muted-badge"]:nth-child(1)')).to have_content('*')
          end
        end
      end
    end

    context 'when creates with an additional scope' do
      before do
        visit(new_project_feature_flag_path(project))
        set_feature_flag_info('mr_train', '')

        within_scope_row(2) do
          within_environment_spec do
            find('.js-env-search > input').set("review/*")
            find('.js-create-button').click
          end
        end

        within_scope_row(2) do
          within_status { find('.project-feature-toggle').click }
        end

        click_button 'Create feature flag'
      end

      it 'shows the created feature flag' do
        within_feature_flag_row(1) do
          expect(page.find('.feature-flag-name')).to have_content('mr_train')
          expect_status_toggle_button_to_be_checked

          within_feature_flag_scopes do
            expect(page.find('[data-qa-selector="feature-flag-scope-info-badge"]:nth-child(1)')).to have_content('*')
            expect(page.find('[data-qa-selector="feature-flag-scope-info-badge"]:nth-child(2)')).to have_content('review/*')
          end
        end
      end
    end

    context 'when searches an environment name for scope creation' do
      let!(:environment) { create(:environment, name: 'production', project: project) }

      before do
        visit(new_project_feature_flag_path(project))
        set_feature_flag_info('mr_train', '')

        within_scope_row(2) do
          within_environment_spec do
            find('.js-env-search > input').set('prod')
            click_button 'production'
          end
        end

        click_button 'Create feature flag'
      end

      it 'shows the created feature flag' do
        within_feature_flag_row(1) do
          expect(page.find('.feature-flag-name')).to have_content('mr_train')
          expect_status_toggle_button_to_be_checked

          within_feature_flag_scopes do
            expect(page.find('[data-qa-selector="feature-flag-scope-info-badge"]:nth-child(1)')).to have_content('*')
            expect(page.find('[data-qa-selector="feature-flag-scope-muted-badge"]:nth-child(2)')).to have_content('production')
          end
        end
      end
    end
  end

  private

  def set_feature_flag_info(name, description)
    fill_in 'Name', with: name
    fill_in 'Description', with: description
  end

  def environment_plus_button
    find('.js-new-environments-dropdown')
  end

  def environment_search_input
    find('.js-new-environments-dropdown input')
  end

  def environment_search_results
    all('.js-new-environments-dropdown button.dropdown-item')
  end
end
