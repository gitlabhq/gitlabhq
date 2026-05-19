# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Work Items List', :js, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :public, group: group) }
  let_it_be(:project_internal) { create(:project_empty_repo, :internal, group: group) }

  context 'if user is signed in as owner' do
    let(:issuable_container) { '[data-testid="issuable-container"]' }

    before_all do
      create(:callout, user: user, feature_name: :work_items_onboarding_modal)
      group.add_owner(user)
    end

    before do
      sign_in(user)
      stub_feature_flags(work_item_features_field: false)

      visit project_work_items_path(project)

      wait_for_all_requests
    end

    # Confidential item filtering for anonymous users is covered by
    # spec/finders/issues_finder_spec.rb

    context 'with pagination' do
      let_it_be(:work_items) do
        create_list(:work_item, 10, :issue, project: project)
        create_list(:work_item, 10, :task, project: project)
        create_list(:work_item, 5, :incident, project: project)
      end

      before do
        visit project_work_items_path(project)
      end

      it_behaves_like 'pagination on the work items list page'

      it 'respects per_page parameter in URL' do
        visit project_work_items_path(project, first_page_size: 50)

        expect(page).to have_selector(issuable_container, count: 25)
      end
    end
  end

  context 'with internal project visibility level' do
    let_it_be(:open_work_item) { create(:work_item, :issue, project: project_internal, title: 'Open work item') }

    let_it_be(:closed_work_item) do
      create(:work_item, :issue, :closed, project: project_internal, title: 'Closed work item')
    end

    context 'when a member views all work items' do
      before_all do
        project_internal.add_developer(user)
      end

      before do
        sign_in(user)
        visit project_work_items_path(project_internal, state: :all)
        wait_for_all_requests
      end

      it_behaves_like 'shows all items in the list' do
        let(:open_item) { open_work_item }
        let(:closed_item) { closed_work_item }
      end
    end
  end
end
