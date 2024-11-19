# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge Requests > User filters by labels', :js, feature_category: :code_review_workflow do
  include FilteredSearchHelpers

  let(:project) { create(:project, :public, :repository) }
  let(:user)    { project.creator }
  let(:mr1) { create(:merge_request, title: 'Bugfix1', source_project: project, target_project: project, source_branch: 'bugfix1') }
  let(:mr2) { create(:merge_request, title: 'Bugfix2', source_project: project, target_project: project, source_branch: 'bugfix2') }

  before do
    bug_label = create(:label, project: project, title: 'bug')
    enhancement_label = create(:label, project: project, title: 'enhancement')
    mr1.labels << bug_label
    mr2.labels << bug_label << enhancement_label

    sign_in(user)
    visit project_merge_requests_path(project)
  end

  context 'filtering by label:none' do
    it 'applies the filter' do
      select_tokens 'Label', '=', 'None', submit: true

      expect(page).to have_issuable_counts(open: 0, closed: 0, all: 0)
      expect(page).not_to have_content 'Bugfix1'
      expect(page).not_to have_content 'Bugfix2'
    end
  end

  context 'filtering by label:~enhancement' do
    it 'applies the filter' do
      select_tokens 'Label', '=', 'enhancement', submit: true

      expect(page).to have_issuable_counts(open: 1, closed: 0, all: 1)
      expect(page).to have_content 'Bugfix2'
      expect(page).not_to have_content 'Bugfix1'
    end
  end

  context 'filtering by label:~enhancement and label:~bug' do
    it 'applies the filters' do
      select_tokens 'Label', '=', 'enhancement', 'Label', '=', 'bug', submit: true

      expect(page).to have_issuable_counts(open: 1, closed: 0, all: 1)
      expect(page).to have_content 'Bugfix2'
    end
  end
end
