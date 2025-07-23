# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Maintainer toggles instance runners', feature_category: :fleet_visibility do
  let_it_be(:user) { create(:user) }

  context 'when vue_project_runners_settings is disabled' do
    # This block (or entire file) can be removed when vue_project_runners_settings is removed

    before do
      stub_feature_flags(vue_project_runners_settings: false)
      sign_in(user)
    end

    describe 'enable instance runners in project settings', :js do
      before do
        visit project_runners_path(project)
      end

      context 'when a project has enabled shared_runners' do
        let_it_be(:project) { create(:project, maintainers: user, shared_runners_enabled: true) }

        it 'instance runners toggle is on' do
          expect(page).to have_selector('[data-testid="instance-runners-toggle"]')
          expect(page).to have_selector('[data-testid="instance-runners-toggle"] .is-checked')
        end
      end

      context 'when a project has disabled shared_runners' do
        let_it_be(:project) { create(:project, maintainers: user, shared_runners_enabled: false) }

        it 'instance runners toggle is off' do
          expect(page).not_to have_selector('[data-testid="instance-runners-toggle"] .is-checked')
        end
      end
    end
  end
end
