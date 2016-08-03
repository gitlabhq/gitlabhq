require 'spec_helper'

describe Projects::BoardIssuesController do
  let(:project) { create(:project_with_board) }
  let(:user)    { create(:user) }

  let(:planning)    { create(:label, project: project, name: 'Planning') }
  let(:development) { create(:label, project: project, name: 'Development') }

  let!(:list1) { create(:list, board: project.board, label: planning, position: 1) }
  let!(:list2) { create(:list, board: project.board, label: development, position: 2) }

  before do
    project.team << [user, :master]
    sign_in(user)
  end

  describe 'GET #index' do
    context 'with valid list id' do
      it 'returns issues that have the list label applied' do
        create(:labeled_issue, project: project, labels: [planning])
        create(:labeled_issue, project: project, labels: [development])
        create(:labeled_issue, project: project, labels: [development])

        list_issues list_id: list2

        parsed_response = JSON.parse(response.body)

        expect(response).to match_response_schema('issue', array: true)
        expect(parsed_response.length).to eq 2
      end
    end

    context 'with invalid list id' do
      it 'returns a not found 404 response' do
        list_issues list_id: 999

        expect(response).to have_http_status(404)
      end
    end

    def list_issues(list_id:)
      get :index, namespace_id: project.namespace.to_param,
                  project_id: project.to_param,
                  list_id: list_id.to_param
    end
  end

  describe 'PATCH #update' do
    let(:issue) { create(:labeled_issue, project: project, labels: [planning]) }

    context 'with valid params' do
      it 'returns a successful 200 response' do
        move issue: issue, from: list1.id, to: list2.id

        expect(response).to have_http_status(200)
      end

      it 'moves issue to the desired list' do
        move issue: issue, from: list1.id, to: list2.id

        expect(issue.reload.labels).to contain_exactly(development)
      end
    end

    context 'with invalid params' do
      it 'returns a unprocessable entity 422 response for invalid lists' do
        move issue: issue, from: nil, to: nil

        expect(response).to have_http_status(422)
      end

      it 'returns a not found 404 response for invalid issue id' do
        move issue: 999, from: list1.id, to: list2.id

        expect(response).to have_http_status(404)
      end
    end

    def move(issue:, from:, to:)
      patch :update, namespace_id: project.namespace.to_param,
                     project_id: project.to_param,
                     id: issue.to_param,
                     issue: { from: from, to: to },
                     format: :json
    end
  end
end
