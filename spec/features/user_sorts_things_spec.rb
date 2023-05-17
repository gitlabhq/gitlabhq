# frozen_string_literal: true

require "spec_helper"

# The main goal of this spec is not to check whether the sorting UI works, but
# to check if the sorting option set by user is being kept persisted while going through pages.
# The `it`s are named here by convention `starting point -> some pages -> final point`.
# All those specs are moved out to this spec intentionally to keep them all in one place.
RSpec.describe "User sorts things", :js do
  include Features::SortingHelpers
  include DashboardHelper

  let_it_be(:project) { create(:project_empty_repo, :public) }
  let_it_be(:current_user) { create(:user) } # Using `current_user` instead of just `user` because of the hardoced call in `assigned_mrs_dashboard_path` which is used below.
  let_it_be(:issue) { create(:issue, project: project, author: current_user) }
  let_it_be(:merge_request) { create(:merge_request, target_project: project, source_project: project, author: current_user) }

  before do
    project.add_developer(current_user)
    sign_in(current_user)
  end

  it "issues -> project home page -> issues", feature_category: :team_planning do
    sort_option = s_('SortOptions|Updated date')

    visit(project_issues_path(project))

    click_button s_('SortOptions|Created date')
    click_button sort_option

    visit(project_path(project))
    visit(project_issues_path(project))

    expect(page).to have_button(sort_option)
  end

  it "merge requests -> dashboard merge requests", feature_category: :code_review_workflow do
    sort_option = s_('SortOptions|Updated date')

    visit(project_merge_requests_path(project))

    pajamas_sort_by(sort_option)

    visit(assigned_mrs_dashboard_path)

    expect(find(".issues-filters")).to have_content(sort_option)
  end
end
