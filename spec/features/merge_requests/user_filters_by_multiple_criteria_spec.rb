# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge requests > User filters by multiple criteria', :js, feature_category: :code_review_workflow do
  include FilteredSearchHelpers

  let!(:project)   { create(:project, :public, :repository) }
  let(:user)       { project.creator }
  let!(:milestone) { create(:milestone, title: 'v1.1', project: project) }
  let!(:wontfix)   { create(:label, project: project, title: "Won't fix") }

  before do
    sign_in(user)
    mr = create(:merge_request, title: 'Bugfix2', author: user, assignees: [user], source_project: project, target_project: project, milestone: milestone)
    mr.labels << wontfix

    visit project_merge_requests_path(project)
  end

  describe 'filtering by label:~"Won\'t fix" and assignee:~bug' do
    it 'applies the filters' do
      select_tokens 'Label', '=', wontfix.title, 'Assignee', '=', user.username, submit: true

      expect(page).to have_issuable_counts(open: 1, closed: 0, all: 1)
      expect(page).to have_content 'Bugfix2'
      expect_empty_search_term
    end
  end

  describe 'filtering by text, author, assignee, milestone, and label' do
    it 'filters by text, author, assignee, milestone, and label' do
      select_tokens 'Author', '=', user.username, 'Assignee', '=', user.username, 'Milestone', '=', milestone.title, 'Label', '=', wontfix.title
      send_keys 'Bug', :enter, :enter

      expect(page).to have_issuable_counts(open: 1, closed: 0, all: 1)
      expect(page).to have_content 'Bugfix2'
      expect_search_term('Bug')
    end
  end
end
