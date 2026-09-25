# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Work Items List', :js, feature_category: :planning_views do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project_internal) { create(:project_empty_repo, :internal, group: group) }

  # Confidential item filtering for anonymous users is covered by
  # spec/finders/issues_finder_spec.rb

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
