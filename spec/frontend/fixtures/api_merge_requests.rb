# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::MergeRequests, '(JavaScript fixtures)', type: :request do
  include ApiHelpers
  include JavaScriptFixturesHelpers

  let_it_be(:admin) { create(:admin, name: 'root') }
  let_it_be(:namespace) { create(:namespace, name: 'gitlab-test' )}
  let_it_be(:project) { create(:project, :repository, namespace: namespace, path: 'lorem-ipsum') }
  let_it_be(:mr) { create(:merge_request, source_project: project) }

  before(:all) do
    clean_frontend_fixtures('api/merge_requests')
  end

  it 'api/merge_requests/get.json' do
    4.times { |i| create(:merge_request, source_project: project, source_branch: "branch-#{i}") }

    get api("/projects/#{project.id}/merge_requests", admin)

    expect(response).to be_successful
  end

  it 'api/merge_requests/versions.json' do
    get api("/projects/#{project.id}/merge_requests/#{mr.iid}/versions", admin)

    expect(response).to be_successful
  end

  it 'api/merge_requests/changes.json' do
    get api("/projects/#{project.id}/merge_requests/#{mr.iid}/changes", admin)

    expect(response).to be_successful
  end
end
