# frozen_string_literal: true

require 'spec_helper'

describe Projects::IssuesController, '(JavaScript fixtures)', type: :controller do
  include JavaScriptFixturesHelpers

  let(:admin) { create(:admin, feed_token: 'feedtoken:coldfeed') }
  let(:namespace) { create(:namespace, name: 'frontend-fixtures' )}
  let(:project) { create(:project_empty_repo, namespace: namespace, path: 'issues-project') }

  render_views

  before(:all) do
    clean_frontend_fixtures('issues/')
  end

  before do
    sign_in(admin)
  end

  after do
    remove_repository(project)
  end

  it 'issues/new-issue.html' do
    get :new, params: {
      namespace_id: project.namespace.to_param,
      project_id: project
    }

    expect(response).to be_successful
  end

  it 'issues/open-issue.html' do
    render_issue(create(:issue, project: project))
  end

  it 'issues/closed-issue.html' do
    render_issue(create(:closed_issue, project: project))
  end

  it 'issues/issue-with-task-list.html' do
    issue = create(:issue, project: project, description: '- [ ] Task List Item')
    render_issue(issue)
  end

  it 'issues/issue_with_comment.html' do
    issue = create(:issue, project: project)
    create(:note, project: project, noteable: issue, note: '- [ ] Task List Item').save
    render_issue(issue)
  end

  it 'issues/issue_list.html' do
    create(:issue, project: project)

    get :index, params: {
      namespace_id: project.namespace.to_param,
      project_id: project
    }

    expect(response).to be_successful
  end

  private

  def render_issue(issue)
    get :show, params: {
      namespace_id: project.namespace.to_param,
      project_id: project,
      id: issue.to_param
    }

    expect(response).to be_successful
  end
end

describe API::Issues, '(JavaScript fixtures)', type: :request do
  include ApiHelpers
  include JavaScriptFixturesHelpers

  def get_related_merge_requests(project_id, issue_iid, user = nil)
    get api("/projects/#{project_id}/issues/#{issue_iid}/related_merge_requests", user)
  end

  def create_referencing_mr(user, project, issue)
    attributes = {
      author: user,
      source_project: project,
      target_project: project,
      source_branch: "master",
      target_branch: "test",
      assignee: user,
      description: "See #{issue.to_reference}"
    }
    create(:merge_request, attributes).tap do |merge_request|
      create(:note, :system, project: issue.project, noteable: issue, author: user, note: merge_request.to_reference(full: true))
    end
  end

  it 'issues/related_merge_requests.json' do
    user = create(:user)
    project = create(:project, :public, creator_id: user.id, namespace: user.namespace)
    issue_title = 'foo'
    issue_description = 'closed'
    milestone = create(:milestone, title: '1.0.0', project: project)
    issue = create :issue,
            author: user,
            assignees: [user],
            project: project,
            milestone: milestone,
            created_at: generate(:past_time),
            updated_at: 1.hour.ago,
            title: issue_title,
            description: issue_description

    project.add_reporter(user)
    create_referencing_mr(user, project, issue)

    create(:merge_request,
           :simple,
           author: user,
           source_project: project,
           target_project: project,
           description: "Some description")
    project2 = create(:project, :public, creator_id: user.id, namespace: user.namespace)
    create_referencing_mr(user, project2, issue).update!(head_pipeline: create(:ci_pipeline))

    get_related_merge_requests(project.id, issue.iid, user)

    expect(response).to be_successful
  end
end
