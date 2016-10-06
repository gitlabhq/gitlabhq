require 'spec_helper'

describe Projects::Boards::IssuesController do
  let(:project) { create(:empty_project) }
  let(:board)   { create(:board, project: project) }
  let(:user)    { create(:user) }
  let(:guest)   { create(:user) }

  let(:planning)    { create(:label, project: project, name: 'Planning') }
  let(:development) { create(:label, project: project, name: 'Development') }

  let!(:list1) { create(:list, board: board, label: planning, position: 0) }
  let!(:list2) { create(:list, board: board, label: development, position: 1) }

  before do
    project.team << [user, :master]
    project.team << [guest, :guest]
  end

  describe 'GET index' do
    context 'with valid list id' do
      it 'returns issues that have the list label applied' do
        johndoe = create(:user, avatar: fixture_file_upload(File.join(Rails.root, 'spec/fixtures/dk.png')))
        create(:labeled_issue, project: project, labels: [planning])
        create(:labeled_issue, project: project, labels: [development])
        create(:labeled_issue, project: project, labels: [development], assignee: johndoe)

        list_issues user: user, board: board, list: list2

        parsed_response = JSON.parse(response.body)

        expect(response).to match_response_schema('issues')
        expect(parsed_response.length).to eq 2
      end
    end

    context 'with invalid board id' do
      it 'returns a not found 404 response' do
        list_issues user: user, board: 999, list: list2

        expect(response).to have_http_status(404)
      end
    end

    context 'with invalid list id' do
      it 'returns a not found 404 response' do
        list_issues user: user, board: board, list: 999

        expect(response).to have_http_status(404)
      end
    end

    context 'with unauthorized user' do
      before do
        allow(Ability).to receive(:allowed?).with(user, :read_project, project).and_return(true)
        allow(Ability).to receive(:allowed?).with(user, :read_issue, project).and_return(false)
      end

      it 'returns a forbidden 403 response' do
        list_issues user: user, board: board, list: list2

        expect(response).to have_http_status(403)
      end
    end

    def list_issues(user:, board:, list:)
      sign_in(user)

      get :index, namespace_id: project.namespace.to_param,
                  project_id: project.to_param,
                  board_id: board.to_param,
                  list_id: list.to_param
    end
  end

  describe 'POST create' do
    context 'with valid params' do
      it 'returns a successful 200 response' do
        create_issue user: user, list: list1, title: 'New issue'

        expect(response).to have_http_status(200)
      end

      it 'returns the created issue' do
        create_issue user: user, list: list1, title: 'New issue'

        expect(response).to match_response_schema('issue')
      end
    end

    context 'with invalid params' do
      context 'when title is nil' do
        it 'returns an unprocessable entity 422 response' do
          create_issue user: user, list: list1, title: nil

          expect(response).to have_http_status(422)
        end
      end

      context 'when list does not belongs to project board' do
        it 'returns a not found 404 response' do
          list = create(:list)

          create_issue user: user, list: list, title: 'New issue'

          expect(response).to have_http_status(404)
        end
      end
    end

    context 'with unauthorized user' do
      it 'returns a forbidden 403 response' do
        create_issue user: guest, list: list1, title: 'New issue'

        expect(response).to have_http_status(403)
      end
    end

    def create_issue(user:, list:, title:)
      sign_in(user)

      post :create, namespace_id: project.namespace.to_param,
                    project_id: project.to_param,
                    list_id: list.to_param,
                    issue: { title: title },
                    format: :json
    end
  end

  describe 'PATCH update' do
    let(:issue) { create(:labeled_issue, project: project, labels: [planning]) }

    context 'with valid params' do
      it 'returns a successful 200 response' do
        move user: user, board: board, issue: issue, from_list_id: list1.id, to_list_id: list2.id

        expect(response).to have_http_status(200)
      end

      it 'moves issue to the desired list' do
        move user: user, board: board, issue: issue, from_list_id: list1.id, to_list_id: list2.id

        expect(issue.reload.labels).to contain_exactly(development)
      end
    end

    context 'with invalid params' do
      it 'returns a unprocessable entity 422 response for invalid lists' do
        move user: user, board: board, issue: issue, from_list_id: nil, to_list_id: nil

        expect(response).to have_http_status(422)
      end

      it 'returns a not found 404 response for invalid board id' do
        move user: user, board: 999, issue: issue, from_list_id: list1.id, to_list_id: list2.id

        expect(response).to have_http_status(404)
      end

      it 'returns a not found 404 response for invalid issue id' do
        move user: user, board: board, issue: 999, from_list_id: list1.id, to_list_id: list2.id

        expect(response).to have_http_status(404)
      end
    end

    context 'with unauthorized user' do
      let(:guest) { create(:user) }

      before do
        project.team << [guest, :guest]
      end

      it 'returns a forbidden 403 response' do
        move user: guest, board: board, issue: issue, from_list_id: list1.id, to_list_id: list2.id

        expect(response).to have_http_status(403)
      end
    end

    def move(user:, board:, issue:, from_list_id:, to_list_id:)
      sign_in(user)

      patch :update, namespace_id: project.namespace.to_param,
                     project_id: project.to_param,
                     board_id: board.to_param,
                     id: issue.to_param,
                     from_list_id: from_list_id,
                     to_list_id: to_list_id,
                     format: :json
    end
  end
end
