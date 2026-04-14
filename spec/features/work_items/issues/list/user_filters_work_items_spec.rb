# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User filters work items', :js, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project_empty_repo, :public) }

  before do
    create(:issue, author: user, project: project, title: 'foobar',
      milestone: create(:milestone, project: project))
    create(:issue, author: user, assignees: [user], project: project, title: 'barbaz')
  end

  it 'allows filtering by issues with no specified assignee' do
    visit project_work_items_path(project, assignee_id: IssuableFinder::Params::FILTER_NONE.capitalize)

    expect(page).to have_content 'foobar'
    expect(page).not_to have_content 'barbaz'
  end
end
