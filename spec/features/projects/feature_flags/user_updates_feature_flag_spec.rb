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
                  description: 'For live trace feature',
                  version: :legacy_flag)
    end

    let!(:scope) { create_scope(feature_flag, 'review/*', true) }

    it 'shows not found error' do
      visit(edit_project_feature_flag_path(project, feature_flag))

      expect(page).to have_text 'Page Not Found'
    end
  end
end
