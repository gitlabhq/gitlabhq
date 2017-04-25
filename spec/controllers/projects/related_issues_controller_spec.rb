require 'rails_helper'

describe Projects::RelatedIssuesController, type: :controller do
  let(:user) { create :user }
  let(:project) { create(:project_empty_repo) }
  let(:issue) { create :issue, project: project }

  describe 'GET #index' do
    let(:issue_b) { create :issue, project: project }
    let(:issue_c) { create :issue, project: project }
    let(:issue_d) { create :issue, project: project }

    let!(:related_issue_a) do
      create(:related_issue, issue: issue,
                             related_issue: issue_b,
                             created_at: 2.days.ago)
    end

    let!(:related_issue_b) do
      create(:related_issue, issue: issue,
                             related_issue: issue_c,
                             created_at: 1.day.ago)
    end

    let!(:related_issue_c) do
      create(:related_issue, issue: issue_d,
                             related_issue: issue,
                             created_at: Date.today)
    end

    it 'returns related issues JSON' do
      sign_in user
      project.team << [user, :developer]

      get :index, namespace_id: issue.project.namespace,
                  project_id: issue.project,
                  issue_id: issue,
                  format: :json

      expect(json_response.size).to eq(3)

      expect(json_response[0]).to eq(
        {
          "title" => issue_b.title,
          "state" => issue_b.state,
          "reference" => issue_b.to_reference(project),
          "path" => "/#{project.full_path}/issues/#{issue_b.iid}"
        }
      )

      expect(json_response[1]).to eq(
        {
          "title" => issue_c.title,
          "state" => issue_c.state,
          "reference" => issue_c.to_reference(project),
          "path" => "/#{project.full_path}/issues/#{issue_c.iid}"
        }
      )

      expect(json_response[2]).to eq(
        {
          "title" => issue_d.title,
          "state" => issue_d.state,
          "reference" => issue_d.to_reference(project),
          "path" => "/#{project.full_path}/issues/#{issue_d.iid}"
        }
      )
    end
  end

  describe 'POST #create' do
    let(:service) { double(CreateRelatedIssueService, execute: service_response) }
    let(:service_response) { { 'message' => 'yay' } }
    let(:issue_references) { double }
    let(:user_role) { :developer }

    before do
      project.team << [user, user_role]

      allow(CreateRelatedIssueService).to receive(:new)
        .with(issue, user, { issue_references: issue_references })
        .and_return(service)
    end

    subject do
      sign_in user

      post :create, namespace_id: issue.project.namespace,
                    project_id: issue.project,
                    issue_id: issue,
                    issue_references: issue_references,
                    format: :json
    end

    context 'with success' do
      it 'returns success JSON' do
        is_expected.to have_http_status(200)
        expect(json_response).to eq(service_response)
      end
    end

    context 'with failure' do
      context 'when unauthorized' do
        let(:user_role) { :guest }

        it 'returns 404' do
          is_expected.to have_http_status(404)
        end
      end

      context 'when failure service result' do
        let(:service_response) { { 'http_status' => 401 } }

        it 'returns failure JSON' do
          is_expected.to have_http_status(401)
          expect(json_response).to eq(service_response)
        end
      end
    end
  end
end
