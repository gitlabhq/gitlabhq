# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Redirect from issues', :js, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :public, group: group, developers: [user]) }

  before do
    # TODO: When removing the feature flag,
    # we won't need the tests for the issues listing page, since we'll be using
    # the work items listing page.
    stub_feature_flags(work_item_planning_view: false)
  end

  context 'for signed in user' do
    before do
      sign_in(user)
    end

    context 'when work_item_planning_view feature flag if disabled' do
      before do
        stub_feature_flags(work_item_planning_view: false)
      end

      it 'do not redirect to work items', :aggregate_failures do
        visit project_issues_path(project)

        expect(page).to have_current_path(project_issues_path(project))
      end
    end

    context 'when work_item_planning_view feature flag if enabled' do
      before do
        stub_feature_flags(work_item_planning_view: true)
      end

      it 'redirects to work items', :aggregate_failures do
        visit project_issues_path(project)

        expect(page).to have_current_path(project_work_items_path(project, 'type[]': 'issue'))
      end

      context 'and the original request has a sorting parameter' do
        it 'redirects to work items', :aggregate_failures do
          visit project_issues_path(project, sort: 'updated_desc')

          expect(page).to have_current_path(project_work_items_path(project, 'type[]': 'issue', sort: 'updated_desc'))
        end
      end
    end
  end
end
