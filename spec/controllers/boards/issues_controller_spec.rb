require 'spec_helper'

describe Boards::IssuesController do
  let(:project) { create(:project) }
  let(:board)   { create(:board, project: project) }
  let(:user)    { create(:user) }
  let(:guest)   { create(:user) }

  let(:planning)    { create(:label, project: project, name: 'Planning') }
  let(:development) { create(:label, project: project, name: 'Development') }

  let!(:list1) { create(:list, board: board, label: planning, position: 0) }
  let!(:list2) { create(:list, board: board, label: development, position: 1) }

  before do
    project.add_master(user)
    project.add_guest(guest)
  end

  describe 'GET index' do
    let(:johndoe) { create(:user, avatar: fixture_file_upload(File.join(Rails.root, 'spec/fixtures/dk.png'))) }

    context 'with invalid board id' do
      it 'returns a not found 404 response' do
        list_issues user: user, board: 999, list: list2

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'when list id is present' do
      context 'with valid list id' do
        it 'returns issues that have the list label applied' do
          issue = create(:labeled_issue, project: project, labels: [planning])
          create(:labeled_issue, project: project, labels: [planning])
          create(:labeled_issue, project: project, labels: [development], due_date: Date.tomorrow)
          create(:labeled_issue, project: project, labels: [development], assignees: [johndoe])
          issue.subscribe(johndoe, project)

          list_issues user: user, board: board, list: list2

          parsed_response = JSON.parse(response.body)

          expect(response).to match_response_schema('issues')
          expect(parsed_response.length).to eq 2
          expect(development.issues.map(&:relative_position)).not_to include(nil)
        end

        it 'avoids N+1 database queries' do
          create(:labeled_issue, project: project, labels: [development])
          control_count = ActiveRecord::QueryRecorder.new { list_issues(user: user, board: board, list: list2) }.count

          # 25 issues is bigger than the page size
          # the relative position will ignore the `#make_sure_position_set` queries
          create_list(:labeled_issue, 25, project: project, labels: [development], assignees: [johndoe], relative_position: 1)

          expect { list_issues(user: user, board: board, list: list2) }.not_to exceed_query_limit(control_count)
        end
      end

      context 'with invalid list id' do
        it 'returns a not found 404 response' do
          list_issues user: user, board: board, list: 999

          expect(response).to have_gitlab_http_status(404)
        end
      end
    end

    context 'when list id is missing' do
      it 'returns opened issues without board labels applied' do
        bug = create(:label, project: project, name: 'Bug')
        create(:issue, project: project)
        create(:labeled_issue, project: project, labels: [planning])
        create(:labeled_issue, project: project, labels: [development])
        create(:labeled_issue, project: project, labels: [bug])

        list_issues user: user, board: board

        parsed_response = JSON.parse(response.body)

        expect(response).to match_response_schema('issues')
        expect(parsed_response.length).to eq 2
      end
    end

    context 'with unauthorized user' do
      before do
        allow(Ability).to receive(:allowed?).and_call_original
        allow(Ability).to receive(:allowed?).with(user, :read_project, project).and_return(true)
        allow(Ability).to receive(:allowed?).with(user, :read_issue, project).and_return(false)
      end

      it 'returns a forbidden 403 response' do
        list_issues user: user, board: board, list: list2

        expect(response).to have_gitlab_http_status(403)
      end
    end

    def list_issues(user:, board:, list: nil)
      sign_in(user)

      params = {
        namespace_id: project.namespace.to_param,
        project_id: project,
        board_id: board.to_param,
        list_id: list.try(:to_param)
      }

      get :index, params.compact
    end
  end

  describe 'POST create' do
    context 'with valid params' do
      it 'returns a successful 200 response' do
        create_issue user: user, board: board, list: list1, title: 'New issue'

        expect(response).to have_gitlab_http_status(200)
      end

      it 'returns the created issue' do
        create_issue user: user, board: board, list: list1, title: 'New issue'

        expect(response).to match_response_schema('issue')
      end
    end

    context 'with invalid params' do
      context 'when title is nil' do
        it 'returns an unprocessable entity 422 response' do
          create_issue user: user, board: board, list: list1, title: nil

          expect(response).to have_gitlab_http_status(422)
        end
      end

      context 'when list does not belongs to project board' do
        it 'returns a not found 404 response' do
          list = create(:list)

          create_issue user: user, board: board, list: list, title: 'New issue'

          expect(response).to have_gitlab_http_status(404)
        end
      end

      context 'with invalid board id' do
        it 'returns a not found 404 response' do
          create_issue user: user, board: 999, list: list1, title: 'New issue'

          expect(response).to have_gitlab_http_status(404)
        end
      end

      context 'with invalid list id' do
        it 'returns a not found 404 response' do
          create_issue user: user, board: board, list: 999, title: 'New issue'

          expect(response).to have_gitlab_http_status(404)
        end
      end
    end

    context 'with unauthorized user' do
      it 'returns a forbidden 403 response' do
        create_issue user: guest, board: board, list: list1, title: 'New issue'

        expect(response).to have_gitlab_http_status(403)
      end
    end

    def create_issue(user:, board:, list:, title:)
      sign_in(user)

      post :create, board_id: board.to_param,
                    list_id: list.to_param,
                    issue: { title: title,  project_id: project.id },
                    format: :json
    end
  end

  describe 'PATCH update' do
    let!(:issue) { create(:labeled_issue, project: project, labels: [planning]) }

    context 'with valid params' do
      it 'returns a successful 200 response' do
        move user: user, board: board, issue: issue, from_list_id: list1.id, to_list_id: list2.id

        expect(response).to have_gitlab_http_status(200)
      end

      it 'moves issue to the desired list' do
        move user: user, board: board, issue: issue, from_list_id: list1.id, to_list_id: list2.id

        expect(issue.reload.labels).to contain_exactly(development)
      end
    end

    context 'with invalid params' do
      it 'returns a unprocessable entity 422 response for invalid lists' do
        move user: user, board: board, issue: issue, from_list_id: nil, to_list_id: nil

        expect(response).to have_gitlab_http_status(422)
      end

      it 'returns a not found 404 response for invalid board id' do
        move user: user, board: 999, issue: issue, from_list_id: list1.id, to_list_id: list2.id

        expect(response).to have_gitlab_http_status(404)
      end

      it 'returns a not found 404 response for invalid issue id' do
        move user: user, board: board, issue: double(id: 999), from_list_id: list1.id, to_list_id: list2.id

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'with unauthorized user' do
      let(:guest) { create(:user) }

      before do
        project.add_guest(guest)
      end

      it 'returns a forbidden 403 response' do
        move user: guest, board: board, issue: issue, from_list_id: list1.id, to_list_id: list2.id

        expect(response).to have_gitlab_http_status(403)
      end
    end

    def move(user:, board:, issue:, from_list_id:, to_list_id:)
      sign_in(user)

      patch :update, namespace_id: project.namespace.to_param,
                     project_id: project.id,
                     board_id: board.to_param,
                     id: issue.id,
                     from_list_id: from_list_id,
                     to_list_id: to_list_id,
                     format: :json
    end
  end
end
