# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User views diffs file-by-file', :js, feature_category: :code_review_workflow do
  let(:merge_request) do
    create(:merge_request_with_diffs, source_project: project, target_project: project, source_branch: 'merge-test')
  end

  let(:project) { create(:project, :repository) }
  let(:user) { create(:user, view_diffs_file_by_file: true) }

  before do
    project.add_developer(user)

    sign_in(user)

    visit(diffs_project_merge_request_path(project, merge_request))

    wait_for_requests
  end

  it 'shows diffs file-by-file' do
    page.within('#diffs') do
      expect(page).to have_selector('.file-holder', count: 1)
      expect(page).to have_selector('.diff-file .file-title', text: 'files/ruby/popen.rb')

      find_by_testid('gl-pagination-next').click

      expect(page).to have_selector('.file-holder', count: 1)
      expect(page).to have_selector('.diff-file .file-title', text: 'files/ruby/regex.rb')
    end
  end
end
