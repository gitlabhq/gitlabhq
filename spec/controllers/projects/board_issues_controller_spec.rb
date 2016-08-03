require 'spec_helper'

describe Projects::BoardIssuesController do
  let(:project) { create(:project_with_board) }
  let(:user)    { create(:user) }

  before do
    project.team << [user, :master]
    sign_in(user)
  end

  describe 'GET #index' do
    context 'with valid list id' do
      it 'returns issues that have the list label applied' do
        label1 = create(:label, project: project, name: 'Planning')
        label2 = create(:label, project: project, name: 'Development')

        create(:labeled_issue, project: project, labels: [label1])
        create(:labeled_issue, project: project, labels: [label2])
        create(:labeled_issue, project: project, labels: [label2])

        create(:list, board: project.board, label: label1, position: 1)
        development = create(:list, board: project.board, label: label2, position: 2)

        get :index, namespace_id: project.namespace.to_param,
                    project_id: project.to_param,
                    list_id: development.to_param

        parsed_response = JSON.parse(response.body)

        expect(response).to match_response_schema('issue', array: true)
        expect(parsed_response.length).to eq 2
      end
    end

    context 'with invalid list id' do
      it 'returns a not found 404 response' do
        get :index, namespace_id: project.namespace.to_param,
                    project_id: project.to_param,
                    id: 999

        expect(response).to have_http_status(404)
      end
    end
  end
end
