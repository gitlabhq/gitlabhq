# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User sees feature flag list', :js do
  include FeatureFlagHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, namespace: user.namespace) }

  before_all do
    project.add_developer(user)
  end

  before do
    sign_in(user)
  end

  context 'with feature flags' do
    before do
      create_flag(project, 'ci_live_trace', false).tap do |feature_flag|
        create_strategy(feature_flag).tap do |strat|
          create(:operations_scope, strategy: strat, environment_scope: '*')
          create(:operations_scope, strategy: strat, environment_scope: 'review/*')
        end
      end
      create_flag(project, 'drop_legacy_artifacts', false)
      create_flag(project, 'mr_train', true).tap do |feature_flag|
        create_strategy(feature_flag).tap do |strat|
          create(:operations_scope, strategy: strat, environment_scope: 'production')
        end
      end
      create(:operations_feature_flag, :new_version_flag, project: project,
             name: 'my_flag', active: false)
    end

    it 'shows the user the first flag' do
      visit(project_feature_flags_path(project))

      within_feature_flag_row(1) do
        expect(page.find('.js-feature-flag-id')).to have_content('^1')
        expect(page.find('.feature-flag-name')).to have_content('ci_live_trace')
        expect_status_toggle_button_not_to_be_checked

        within_feature_flag_scopes do
          expect(page.find('[data-testid="strategy-badge"]')).to have_content('All Users: All Environments, review/*')
        end
      end
    end

    it 'shows the user the second flag' do
      visit(project_feature_flags_path(project))

      within_feature_flag_row(2) do
        expect(page.find('.js-feature-flag-id')).to have_content('^2')
        expect(page.find('.feature-flag-name')).to have_content('drop_legacy_artifacts')
        expect_status_toggle_button_not_to_be_checked
      end
    end

    it 'shows the user the third flag' do
      visit(project_feature_flags_path(project))

      within_feature_flag_row(3) do
        expect(page.find('.js-feature-flag-id')).to have_content('^3')
        expect(page.find('.feature-flag-name')).to have_content('mr_train')
        expect_status_toggle_button_to_be_checked

        within_feature_flag_scopes do
          expect(page.find('[data-testid="strategy-badge"]')).to have_content('All Users: production')
        end
      end
    end

    it 'allows the user to update the status toggle' do
      visit(project_feature_flags_path(project))

      within_feature_flag_row(1) do
        status_toggle_button.click

        expect_status_toggle_button_to_be_checked
      end
    end
  end

  context 'when there are no feature flags' do
    before do
      visit(project_feature_flags_path(project))
    end

    it 'shows the empty page' do
      expect(page).to have_text 'Get started with feature flags'
      expect(page).to have_selector('.btn-confirm', text: 'New feature flag')
      expect(page).to have_selector('[data-qa-selector="configure_feature_flags_button"]', text: 'Configure')
    end
  end
end
