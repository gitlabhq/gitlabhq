# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User sorts merge requests', :js, feature_category: :code_review_workflow do
  include CookieHelper
  include Features::SortingHelpers

  let!(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  let!(:merge_request2) do
    create(:merge_request_with_diffs, source_project: project, target_project: project, source_branch: 'merge-test')
  end

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:group_member) { create(:group_member, :maintainer, user: user, group: group) }
  let_it_be(:project) { create(:project, :public, group: group) }

  before do
    sign_in(user)

    visit(project_merge_requests_path(project))
  end

  it 'keeps the sort option' do
    pajamas_sort_by(s_('SortOptions|Milestone'), from: s_('SortOptions|Created date'))

    visit(merge_requests_dashboard_path(assignee_username: user.username))

    expect(find('.filter-dropdown-container button.gl-new-dropdown-toggle')).to have_content('Milestone')

    visit(project_merge_requests_path(project))

    expect(find('.sort-dropdown-container')).to have_content('Milestone')

    visit(merge_requests_group_path(group))

    expect(find('.sort-dropdown-container')).to have_content('Milestone')
  end

  it 'fallbacks to issuable_sort cookie key when remembering the sorting option' do
    set_cookie('issuable_sort', 'milestone')

    visit(merge_requests_dashboard_path(assignee_username: user.username))

    expect(find('.filter-dropdown-container button.gl-new-dropdown-toggle')).to have_content('Milestone')
  end

  it 'separates remember sorting with issues', :js do
    create(:issue, project: project)

    pajamas_sort_by(s_('SortOptions|Milestone'), from: s_('SortOptions|Created date'))

    visit(project_issues_path(project))

    expect(page).not_to have_button('Milestone')
  end

  context 'when merge requests have awards' do
    before do
      create_list(:award_emoji, 2, awardable: merge_request)
      create(:award_emoji, :downvote, awardable: merge_request)

      create(:award_emoji, awardable: merge_request2)
      create_list(:award_emoji, 2, :downvote, awardable: merge_request2)
    end

    it 'sorts by popularity' do
      pajamas_sort_by(s_('SortOptions|Popularity'), from: s_('SortOptions|Created date'))

      page.within('.issuable-list') do
        page.within('li.merge-request:nth-child(1)') do
          expect(page).to have_content(merge_request.title)
          expect(page).to have_content('2 1')
        end

        page.within('li.merge-request:nth-child(2)') do
          expect(page).to have_content(merge_request2.title)
          expect(page).to have_content('1 2')
        end
      end
    end
  end
end
