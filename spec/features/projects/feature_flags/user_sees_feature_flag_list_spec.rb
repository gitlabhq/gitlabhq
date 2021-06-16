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

  context 'with legacy feature flags' do
    before do
      create_flag(project, 'ci_live_trace', false, version: :legacy_flag).tap do |feature_flag|
        create_scope(feature_flag, 'review/*', true)
      end
      create_flag(project, 'drop_legacy_artifacts', false, version: :legacy_flag)
      create_flag(project, 'mr_train', true, version: :legacy_flag).tap do |feature_flag|
        create_scope(feature_flag, 'production', false)
      end
    end

    it 'shows empty page' do
      visit(project_feature_flags_path(project))

      expect(page).to have_text 'Get started with feature flags'
      expect(page).to have_selector('.btn-confirm', text: 'New feature flag')
      expect(page).to have_selector('[data-qa-selector="configure_feature_flags_button"]', text: 'Configure')
    end
  end

  context 'with new version flags' do
    before do
      create(:operations_feature_flag, :new_version_flag, project: project,
             name: 'my_flag', active: false)
    end

    it 'user updates the status toggle' do
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

    it 'shows empty page' do
      expect(page).to have_text 'Get started with feature flags'
      expect(page).to have_selector('.btn-confirm', text: 'New feature flag')
      expect(page).to have_selector('[data-qa-selector="configure_feature_flags_button"]', text: 'Configure')
    end
  end
end
