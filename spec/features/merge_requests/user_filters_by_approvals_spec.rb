# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge Requests > User filters', :js, feature_category: :code_review_workflow do
  include FilteredSearchHelpers

  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:user)    { project.creator }
  let_it_be(:group_user) { create(:user) }
  let_it_be(:first_user) { create(:user) }

  before_all do
    project.add_developer(first_user)
    project.add_developer(group_user)
  end

  before do
    sign_in(user)
    visit project_merge_requests_path(project)
  end

  context 'by "approved by"' do
    let_it_be(:merge_request) { create(:merge_request, title: 'Bugfix3', source_project: project, source_branch: 'bugfix3') }

    let_it_be(:merge_request_with_first_user_approval) do
      create(:merge_request, source_project: project, title: 'Bugfix5').tap do |mr|
        create(:approval, merge_request: mr, user: first_user)
      end
    end

    let_it_be(:merge_request_with_group_user_approved) do
      group = create(:group)
      group.add_developer(group_user)

      create(:merge_request, source_project: project, title: 'Bugfix6', source_branch: 'bugfix6').tap do |mr|
        create(:approval, merge_request: mr, user: group_user)
      end
    end

    context 'filtering by approved-by:none' do
      it 'applies the filter' do
        select_tokens 'Approved-By', '=', 'None', submit: true

        expect(page).to have_issuable_counts(open: 1, closed: 0, all: 1)

        expect(page).not_to have_content 'Bugfix5'
        expect(page).not_to have_content 'Bugfix6'
        expect(page).to have_content 'Bugfix3'
      end
    end

    context 'filtering by approved-by:any' do
      it 'applies the filter' do
        select_tokens 'Approved-By', '=', 'Any', submit: true

        expect(page).to have_issuable_counts(open: 2, closed: 0, all: 2)

        expect(page).to have_content 'Bugfix5'
        expect(page).not_to have_content 'Bugfix3'
      end
    end

    context 'filtering by approved-by:@username' do
      it 'applies the filter' do
        select_tokens 'Approved-By', '=', first_user.username, submit: true

        expect(page).to have_issuable_counts(open: 1, closed: 0, all: 1)

        expect(page).to have_content 'Bugfix5'
        expect(page).not_to have_content 'Bugfix3'
      end
    end

    context 'filtering by an approver from a group' do
      it 'applies the filter' do
        select_tokens 'Approved-By', '=', group_user.username, submit: true

        expect(page).to have_issuable_counts(open: 1, closed: 0, all: 1)

        expect(page).to have_content 'Bugfix6'
        expect(page).not_to have_content 'Bugfix5'
        expect(page).not_to have_content 'Bugfix3'
      end
    end
  end
end
