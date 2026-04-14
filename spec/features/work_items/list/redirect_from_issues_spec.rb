# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Redirect from issues', :js, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :public, group: group, developers: [user]) }

  context 'for signed in user' do
    before do
      create(:callout, user: user, feature_name: :work_items_onboarding_modal)
      sign_in(user)
    end

    it 'redirects to work items', :aggregate_failures do
      visit project_issues_path(project)

      expect(page).to have_current_path(project_work_items_path(project))
    end

    context 'and the original request has a sorting parameter' do
      it 'redirects to work items', :aggregate_failures do
        visit project_issues_path(project, sort: 'updated_desc')

        expect(page).to have_current_path(project_work_items_path(project, sort: 'updated_desc'))
      end
    end
  end
end
