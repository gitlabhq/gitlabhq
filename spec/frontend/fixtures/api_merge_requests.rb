# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::MergeRequests, '(JavaScript fixtures)', type: :request, feature_category: :code_review_workflow do
  include ApiHelpers
  include JavaScriptFixturesHelpers

  let_it_be(:namespace, freeze: false) { create(:namespace, name: 'gitlab-test') }
  let_it_be(:project, freeze: false) { create(:project, :repository, namespace: namespace, path: 'lorem-ipsum') }
  let_it_be(:early_mrs, freeze: false) do
    4.times { |i| create(:merge_request, source_project: project, source_branch: "branch-#{i}") }
  end

  let_it_be(:mr, freeze: false) { create(:merge_request, source_project: project) }
  let_it_be(:user, freeze: false) { project.owner }

  it 'api/merge_requests/get.json' do
    get api("/projects/#{project.id}/merge_requests", user)

    expect(response).to be_successful
  end

  it 'api/merge_requests/versions.json' do
    get api("/projects/#{project.id}/merge_requests/#{mr.iid}/versions", user)

    expect(response).to be_successful
  end

  it 'api/merge_requests/changes.json' do
    get api("/projects/#{project.id}/merge_requests/#{mr.iid}/changes", user)

    expect(response).to be_successful
  end
end
