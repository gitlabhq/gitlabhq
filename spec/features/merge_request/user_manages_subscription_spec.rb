# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User manages subscription', :js, feature_category: :code_review_workflow do
  let(:project) { create(:project, :public, :repository) }
  let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  let(:user) { create(:user) }
  let(:moved_mr_sidebar_enabled) { false }

  before do
    stub_feature_flags(moved_mr_sidebar: moved_mr_sidebar_enabled)

    project.add_maintainer(user)
    sign_in(user)

    visit(merge_request_path(merge_request))
  end

  context 'moved sidebar flag disabled' do
    it 'toggles subscription' do
      page.within('[data-testid="subscription-toggle"]') do
        wait_for_requests

        expect(page).to have_css 'button:not(.is-checked)'
        find('button:not(.is-checked)').click

        wait_for_requests

        expect(page).to have_css 'button.is-checked'
        find('button.is-checked').click

        wait_for_requests

        expect(page).to have_css 'button:not(.is-checked)'
      end
    end
  end

  context 'moved sidebar flag enabled' do
    let(:moved_mr_sidebar_enabled) { true }

    it 'toggles subscription' do
      wait_for_requests

      find('[data-testid="merge-request-actions"]').click

      expect(page).to have_selector('.gl-toggle:not(.is-checked)')
      find('[data-testid="notifications-toggle"] .gl-toggle').click

      wait_for_requests

      expect(page).to have_selector('.gl-toggle.is-checked')
      find('[data-testid="notifications-toggle"] .gl-toggle').click

      wait_for_requests

      expect(page).to have_selector('.gl-toggle:not(.is-checked)')
    end
  end
end
