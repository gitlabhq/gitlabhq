require 'spec_helper'

describe Projects::Boards::IssuesController do
  let(:project) { create(:project_with_board) }
  let(:user)    { create(:user) }

  let(:planning)    { create(:label, project: project, name: 'Planning') }
  let(:development) { create(:label, project: project, name: 'Development') }

  let!(:list1) { create(:list, board: project.board, label: planning, position: 0) }
  let!(:list2) { create(:list, board: project.board, label: development, position: 1) }

  before do
    project.team << [user, :master]
  end

  describe 'GET index' do
    context 'with valid list id' do
      it 'returns issues that have the list label applied' do
        johndoe = create(:user, avatar: fixture_file_upload(File.join(Rails.root, 'spec/fixtures/dk.png')))
        create(:labeled_issue, project: project, labels: [planning])
        create(:labeled_issue, project: project, labels: [development])
        create(:labeled_issue, project: project, labels: [development], assignee: johndoe)

        list_issues user: user, list_id: list2

        parsed_response = JSON.parse(response.body)

        expect(response).to match_response_schema('issues')
        expect(parsed_response.length).to eq 2
      end
    end

    context 'with invalid list id' do
      it 'returns a not found 404 response' do
        list_issues user: user, list_id: 999

        expect(response).to have_http_status(404)
      end
    end

    context 'with unauthorized user' do
      it 'returns a successful 403 response' do
        allow(Ability.abilities).to receive(:allowed?).with(user, :read_project, project).and_return(true)
        allow(Ability.abilities).to receive(:allowed?).with(user, :read_issue, project).and_return(false)

        list_issues user: user, list_id: list2

        expect(response).to have_http_status(403)
      end
    end

    def list_issues(user:, list_id:)
      sign_in(user)

      get :index, namespace_id: project.namespace.to_param,
                  project_id: project.to_param,
                  list_id: list_id.to_param
    end
  end

  describe 'PATCH update' do
    let(:issue) { create(:labeled_issue, project: project, labels: [planning]) }

    context 'with valid params' do
      it 'returns a successful 200 response' do
        move user: user, issue: issue, from_list_id: list1.id, to_list_id: list2.id

        expect(response).to have_http_status(200)
      end

      it 'moves issue to the desired list' do
        move user: user, issue: issue, from_list_id: list1.id, to_list_id: list2.id

        expect(issue.reload.labels).to contain_exactly(development)
      end
    end

    context 'with invalid params' do
      it 'returns a unprocessable entity 422 response for invalid lists' do
        move user: user, issue: issue, from_list_id: nil, to_list_id: nil

        expect(response).to have_http_status(422)
      end

      it 'returns a not found 404 response for invalid issue id' do
        move user: user, issue: 999, from_list_id: list1.id, to_list_id: list2.id

        expect(response).to have_http_status(404)
      end
    end

    context 'with unauthorized user' do
      let(:guest) { create(:user) }

      before do
        project.team << [guest, :guest]
      end

      it 'returns a successful 403 response' do
        move user: guest, issue: issue, from_list_id: list1.id, to_list_id: list2.id

        expect(response).to have_http_status(403)
      end
    end

    def move(user:, issue:, from_list_id:, to_list_id:)
      sign_in(user)

      patch :update, namespace_id: project.namespace.to_param,
                     project_id: project.to_param,
                     id: issue.to_param,
                     from_list_id: from_list_id,
                     to_list_id: to_list_id,
                     format: :json
    end
  end
end
