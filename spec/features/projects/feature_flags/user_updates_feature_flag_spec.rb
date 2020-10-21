# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User updates feature flag', :js do
  include FeatureFlagHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, namespace: user.namespace) }

  before_all do
    project.add_developer(user)
  end

  before do
    stub_feature_flags(
      feature_flag_permissions: false,
      feature_flags_legacy_read_only_override: false
    )
    sign_in(user)
  end

  context 'with a new version feature flag' do
    let!(:feature_flag) do
      create_flag(project, 'test_flag', false, version: Operations::FeatureFlag.versions['new_version_flag'],
                  description: 'For testing')
    end

    let!(:strategy) do
      create(:operations_strategy, feature_flag: feature_flag,
             name: 'default', parameters: {})
    end

    let!(:scope) do
      create(:operations_scope, strategy: strategy, environment_scope: '*')
    end

    it 'user adds a second strategy' do
      visit(edit_project_feature_flag_path(project, feature_flag))

      wait_for_requests

      click_button 'Add strategy'
      within_strategy_row(2) do
        select 'Percent of users', from: 'Type'
        fill_in 'Percentage', with: '15'
      end
      click_button 'Save changes'

      edit_feature_flag_button.click

      within_strategy_row(1) do
        expect(page).to have_text 'All users'
        expect(page).to have_text 'All environments'
      end
      within_strategy_row(2) do
        expect(page).to have_text 'Percent of users'
        expect(page).to have_field 'Percentage', with: '15'
        expect(page).to have_text 'All environments'
      end
    end

    it 'user toggles the flag on' do
      visit(edit_project_feature_flag_path(project, feature_flag))
      status_toggle_button.click
      click_button 'Save changes'

      within_feature_flag_row(1) do
        expect_status_toggle_button_to_be_checked
      end
    end
  end

  context 'with a legacy feature flag' do
    let!(:feature_flag) do
      create_flag(project, 'ci_live_trace', true,
                  description: 'For live trace feature')
    end

    let!(:scope) { create_scope(feature_flag, 'review/*', true) }

    context 'when legacy flags are editable' do
      before do
        stub_feature_flags(feature_flags_legacy_read_only: false)

        visit(edit_project_feature_flag_path(project, feature_flag))
      end

      it 'user sees persisted default scope' do
        within_scope_row(1) do
          within_environment_spec do
            expect(page).to have_content('* (All Environments)')
          end

          within_status do
            expect(find('.project-feature-toggle')['aria-label'])
              .to eq('Toggle Status: ON')
          end
        end
      end

      context 'when user updates the status of a scope' do
        before do
          within_scope_row(2) do
            within_status { find('.project-feature-toggle').click }
          end

          click_button 'Save changes'
          expect(page).to have_current_path(project_feature_flags_path(project))
        end

        it 'shows the updated feature flag' do
          within_feature_flag_row(1) do
            expect(page.find('.feature-flag-name')).to have_content('ci_live_trace')
            expect_status_toggle_button_to_be_checked

            within_feature_flag_scopes do
              expect(page.find('.badge:nth-child(1)')).to have_content('*')
              expect(page.find('.badge:nth-child(1)')['class']).to include('badge-info')
              expect(page.find('.badge:nth-child(2)')).to have_content('review/*')
              expect(page.find('.badge:nth-child(2)')['class']).to include('badge-muted')
            end
          end
        end
      end

      context 'when user adds a new scope' do
        before do
          within_scope_row(3) do
            within_environment_spec do
              find('.js-env-search > input').set('production')
              find('.js-create-button').click
            end
          end

          click_button 'Save changes'
          expect(page).to have_current_path(project_feature_flags_path(project))
        end

        it 'shows the newly created scope' do
          within_feature_flag_row(1) do
            within_feature_flag_scopes do
              expect(page.find('.badge:nth-child(3)')).to have_content('production')
              expect(page.find('.badge:nth-child(3)')['class']).to include('badge-muted')
            end
          end
        end
      end

      context 'when user deletes a scope' do
        before do
          within_scope_row(2) do
            within_delete { find('.js-delete-scope').click }
          end

          click_button 'Save changes'
          expect(page).to have_current_path(project_feature_flags_path(project))
        end

        it 'shows the updated feature flag' do
          within_feature_flag_row(1) do
            within_feature_flag_scopes do
              expect(page).to have_css('.badge:nth-child(1)')
              expect(page).not_to have_css('.badge:nth-child(2)')
            end
          end
        end
      end
    end

    context 'when legacy flags are read-only' do
      it 'the user cannot edit the flag' do
        visit(edit_project_feature_flag_path(project, feature_flag))

        expect(page).to have_text 'This feature flag is read-only, and it will be removed in 14.0.'
        expect(page).to have_css('button.js-ff-submit.disabled')
      end
    end

    context 'when legacy flags are read-only, but the override is active for one project' do
      it 'the user can edit the flag' do
        stub_feature_flags(feature_flags_legacy_read_only_override: project)

        visit(edit_project_feature_flag_path(project, feature_flag))
        status_toggle_button.click
        click_button 'Save changes'

        expect(page).to have_current_path(project_feature_flags_path(project))
        within_feature_flag_row(1) do
          expect_status_toggle_button_not_to_be_checked
        end
      end
    end
  end
end
