# frozen_string_literal: true

require 'spec_helper'

describe 'Merge requests > User filters by multiple criteria', :js do
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
      input_filtered_search("label=~\"Won't fix\" assignee=@#{user.username}")

      expect(page).to have_issuable_counts(open: 1, closed: 0, all: 1)
      expect(page).to have_content 'Bugfix2'
      expect_filtered_search_input_empty
    end
  end

  describe 'filtering by text, author, assignee, milestone, and label' do
    it 'filters by text, author, assignee, milestone, and label' do
      input_filtered_search_keys("author=@#{user.username} assignee=@#{user.username} milestone=%\"v1.1\" label=~\"Won't fix\" Bug")

      expect(page).to have_issuable_counts(open: 1, closed: 0, all: 1)
      expect(page).to have_content 'Bugfix2'
      expect_filtered_search_input('Bug')
    end
  end
end
