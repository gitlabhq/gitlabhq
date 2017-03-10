require 'rails_helper'

feature 'Pipeline status icon on merge requests index', feature: true do
  let(:project)           { create(:project, :public) }
  let!(:user)             { create(:user) }
  let(:status_per_branch) { { branch_1: 'running', branch_2: 'failed', branch_3: 'success' } }

  before do
    status_per_branch.each do |branch, status|
      create(:ci_empty_pipeline, project: project, ref: branch, status: status, sha: project.commit.id)
      create(:merge_request, title: FFaker::Lorem.sentence, source_project: project, source_branch: branch)
    end

    create(:merge_request, title: FFaker::Lorem.sentence, source_project: project, source_branch: 'branch_1', target_branch: 'not_master')

    project.add_master(user)
    login_as(user)

    visit namespace_project_merge_requests_path(project.namespace, project)
  end

  it 'shows pipeline status for each merge request' do
    merge_requests = project.merge_requests

    merge_requests.each do |mr|
      page.find("#merge_request_#{mr.id}") do |item|
        expect(item).to have_selector("ci-status-icon-#{status_per_branch[mr.source_branch]}")
      end
    end
  end
end
