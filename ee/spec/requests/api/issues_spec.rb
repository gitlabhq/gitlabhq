require 'spec_helper'

describe API::Issues, :mailer do
  set(:user) { create(:user) }
  set(:project) do
    create(:project, :public, creator_id: user.id, namespace: user.namespace)
  end

  let(:user2)       { create(:user) }
  set(:author)      { create(:author) }
  set(:assignee)    { create(:assignee) }
  let(:issue_title)       { 'foo' }
  let(:issue_description) { 'closed' }
  let!(:issue) do
    create :issue,
           author: user,
           assignees: [user],
           project: project,
           milestone: milestone,
           created_at: generate(:past_time),
           updated_at: 1.hour.ago,
           title: issue_title,
           description: issue_description
  end
  set(:milestone) { create(:milestone, title: '1.0.0', project: project) }

  before(:all) do
    project.add_reporter(user)
  end

  describe "GET /issues" do
    context "when authenticated" do
      it 'matches V4 response schema' do
        get api('/issues', user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to match_response_schema('public_api/v4/issues', dir: 'ee')
      end
    end
  end

  describe "POST /projects/:id/issues" do
    it 'creates a new project issue' do
      post api("/projects/#{project.id}/issues", user),
        title: 'new issue', labels: 'label, label2', weight: 101,
        assignee_ids: [user2.id]

      expect(response).to have_gitlab_http_status(201)
      expect(json_response['title']).to eq('new issue')
      expect(json_response['description']).to be_nil
      expect(json_response['labels']).to eq(%w(label label2))
      expect(json_response['confidential']).to be_falsy
      expect(json_response['weight']).to eq(101)
      expect(json_response['assignee']['name']).to eq(user2.name)
      expect(json_response['assignees'].first['name']).to eq(user2.name)
    end
  end

  describe 'PUT /projects/:id/issues/:issue_id to update weight' do
    it 'updates an issue with no weight' do
      put api("/projects/#{project.id}/issues/#{issue.iid}", user), weight: 101

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['weight']).to eq(101)
    end

    it 'removes a weight from an issue' do
      weighted_issue = create(:issue, project: project, weight: 2)

      put api("/projects/#{project.id}/issues/#{weighted_issue.iid}", user), weight: nil

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['weight']).to be_nil
    end

    it 'returns 400 if weight is less than minimum weight' do
      put api("/projects/#{project.id}/issues/#{issue.iid}", user), weight: -1

      expect(response).to have_gitlab_http_status(400)
      expect(json_response['message']['weight']).to be_present
    end

    it 'adds a note when the weight is changed' do
      expect do
        put api("/projects/#{project.id}/issues/#{issue.iid}", user), weight: 9
      end.to change { Note.count }.by(1)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['weight']).to eq(9)
    end

    context 'issuable weights unlicensed' do
      before do
        stub_licensed_features(issue_weights: false)
      end

      it 'ignores the update' do
        put api("/projects/#{project.id}/issues/#{issue.iid}", user), weight: 5

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['weight']).to be_nil
        expect(issue.reload.read_attribute(:weight)).to be_nil
      end
    end
  end

  def expect_paginated_array_response(size: nil)
    expect(response).to have_gitlab_http_status(200)
    expect(response).to include_pagination_headers
    expect(json_response).to be_an Array
    expect(json_response.length).to eq(size) if size
  end
end
