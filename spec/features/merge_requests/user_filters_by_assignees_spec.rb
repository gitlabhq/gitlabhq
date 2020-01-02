# frozen_string_literal: true

require 'spec_helper'

describe 'Merge Requests > User filters by assignees', :js do
  include FilteredSearchHelpers

  let(:project) { create(:project, :public, :repository) }
  let(:user)    { project.creator }

  before do
    create(:merge_request, assignees: [user], title: 'Bugfix1', source_project: project, target_project: project, source_branch: 'bugfix1')
    create(:merge_request, title: 'Bugfix2', source_project: project, target_project: project, source_branch: 'bugfix2')

    sign_in(user)
    visit project_merge_requests_path(project)
  end

  context 'filtering by assignee:none' do
    it 'applies the filter' do
      input_filtered_search('assignee=none')

      expect(page).to have_issuable_counts(open: 1, closed: 0, all: 1)
      expect(page).not_to have_content 'Bugfix1'
      expect(page).to have_content 'Bugfix2'
    end
  end

  context 'filtering by assignee=@username' do
    it 'applies the filter' do
      input_filtered_search("assignee=@#{user.username}")

      expect(page).to have_issuable_counts(open: 1, closed: 0, all: 1)
      expect(page).to have_content 'Bugfix1'
      expect(page).not_to have_content 'Bugfix2'
    end
  end
end
