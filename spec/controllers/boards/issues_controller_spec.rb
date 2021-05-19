# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Boards::IssuesController do
  include ExternalAuthorizationServiceHelpers

  let(:project) { create(:project, :private) }
  let(:board)   { create(:board, project: project) }
  let(:user)    { create(:user) }
  let(:guest)   { create(:user) }

  let(:planning)    { create(:label, project: project, name: 'Planning') }
  let(:development) { create(:label, project: project, name: 'Development') }

  let!(:list1) { create(:list, board: board, label: planning, position: 0) }
  let!(:list2) { create(:list, board: board, label: development, position: 1) }

  before do
    project.add_maintainer(user)
    project.add_guest(guest)
  end

  describe 'GET index', :request_store do
    let(:johndoe) { create(:user, avatar: fixture_file_upload(File.join('spec/fixtures/dk.png'))) }

    context 'with invalid board id' do
      it 'returns a not found 404 response' do
        list_issues user: user, board: non_existing_record_id, list: list2

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when list id is present' do
      context 'with valid list id' do
        let(:group) { create(:group, :private, projects: [project]) }
        let(:group_board) { create(:board, group: group) }
        let!(:list3) { create(:list, board: group_board, label: development, position: 2) }
        let(:sub_group_1) { create(:group, :private, parent: group) }

        before do
          group.add_maintainer(user)
        end

        it 'returns issues that have the list label applied' do
          issue = create(:labeled_issue, project: project, labels: [planning])
          create(:labeled_issue, project: project, labels: [planning])
          create(:labeled_issue, project: project, labels: [development], due_date: Date.tomorrow)
          create(:labeled_issue, project: project, labels: [development], assignees: [johndoe])
          issue.subscribe(johndoe, project)
          expect(Issue).to receive(:move_nulls_to_end)

          list_issues user: user, board: board, list: list2

          expect(response).to match_response_schema('entities/issue_boards')
          expect(json_response['issues'].length).to eq 2
          expect(development.issues.map(&:relative_position)).not_to include(nil)
        end

        it 'returns issues by closed_at in descending order in closed list' do
          create(:closed_issue, project: project, title: 'New Issue 1', closed_at: 1.day.ago)
          create(:closed_issue, project: project, title: 'New Issue 2', closed_at: 1.week.ago)

          list_issues user: user, board: board, list: board.lists.last.id

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['issues'].length).to eq(2)
          expect(json_response['issues'][0]['title']).to eq('New Issue 1')
          expect(json_response['issues'][1]['title']).to eq('New Issue 2')
        end

        it 'avoids N+1 database queries' do
          create(:labeled_issue, project: project, labels: [development])
          control_count = ActiveRecord::QueryRecorder.new { list_issues(user: user, board: board, list: list2) }.count

          # 25 issues is bigger than the page size
          # the relative position will ignore the `#make_sure_position_set` queries
          create_list(:labeled_issue, 25, project: project, labels: [development], assignees: [johndoe], relative_position: 1)

          expect { list_issues(user: user, board: board, list: list2) }.not_to exceed_query_limit(control_count)
        end

        it 'avoids N+1 database queries when adding a project', :request_store do
          create(:labeled_issue, project: project, labels: [development])
          control_count = ActiveRecord::QueryRecorder.new { list_issues(user: user, board: group_board, list: list3) }.count

          2.times do
            p = create(:project, group: group)
            create(:labeled_issue, project: p, labels: [development])
          end

          project_2 = create(:project, group: group)
          create(:labeled_issue, project: project_2, labels: [development], assignees: [johndoe])

          # because each issue without relative_position must be updated with
          # a different value, we have 8 extra queries per issue
          expect { list_issues(user: user, board: group_board, list: list3) }.not_to exceed_query_limit(control_count + (2 * 8 - 1))
        end

        it 'avoids N+1 database queries when adding a subgroup, project, and issue' do
          create(:project, group: sub_group_1)
          create(:labeled_issue, project: project, labels: [development])
          control_count = ActiveRecord::QueryRecorder.new { list_issues(user: user, board: group_board, list: list3) }.count
          project_2 = create(:project, group: group)

          2.times do
            p = create(:project, group: sub_group_1)
            create(:labeled_issue, project: p, labels: [development])
          end

          create(:labeled_issue, project: project_2, labels: [development], assignees: [johndoe])

          expect { list_issues(user: user, board: group_board, list: list3) }.not_to exceed_query_limit(control_count + (2 * 8 - 1))
        end

        it 'does not query issues table more than once' do
          recorder = ActiveRecord::QueryRecorder.new { list_issues(user: user, board: board, list: list1) }
          query_count = recorder.occurrences.select { |query,| query.start_with?('SELECT issues.*') }.each_value.first

          expect(query_count).to eq(1)
        end

        context 'when block_issue_repositioning feature flag is enabled' do
          before do
            stub_feature_flags(block_issue_repositioning: true)
          end

          it 'does not reposition issues with null position' do
            expect(Issue).not_to receive(:move_nulls_to_end)

            list_issues(user: user, board: group_board, list: list3)
          end
        end
      end

      context 'with invalid list id' do
        it 'returns a not found 404 response' do
          list_issues user: user, board: board, list: non_existing_record_id

          expect(response).to have_gitlab_http_status(:not_found)
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

        expect(response).to match_response_schema('entities/issue_boards')
        expect(json_response['issues'].length).to eq 2
      end
    end

    context 'with unauthorized user' do
      let(:unauth_user) { create(:user) }

      it 'returns a forbidden 403 response' do
        list_issues user: unauth_user, board: board, list: list2

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'with external authorization' do
      before do
        sign_in(user)
        enable_external_authorization_service_check
      end

      it 'returns a 403 for group boards' do
        group = create(:group)
        group_board = create(:board, group: group)

        list_issues(user: user, board: group_board)

        expect(response).to have_gitlab_http_status(:forbidden)
      end

      it 'is successful for project boards' do
        project_board = create(:board, project: project)

        list_issues(user: user, board: project_board)

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    describe 'PUT bulk_move' do
      let(:todo) { create(:group_label, group: group, name: 'Todo') }
      let(:development) { create(:group_label, group: group, name: 'Development') }
      let(:user) { create(:group_member, :maintainer, user: create(:user), group: group ).user }
      let(:guest) { create(:group_member, :guest, user: create(:user), group: group ).user }
      let(:project) { create(:project, group: group) }
      let(:group) { create(:group) }
      let(:board) { create(:board, project: project) }
      let(:list1) { create(:list, board: board, label: todo, position: 0) }
      let(:list2) { create(:list, board: board, label: development, position: 1) }
      let(:issue1) { create(:labeled_issue, project: project, labels: [todo], author: user, relative_position: 10) }
      let(:issue2) { create(:labeled_issue, project: project, labels: [todo], author: user, relative_position: 20) }
      let(:issue3) { create(:labeled_issue, project: project, labels: [todo], author: user, relative_position: 30) }
      let(:issue4) { create(:labeled_issue, project: project, labels: [development], author: user, relative_position: 100) }

      let(:move_params) do
        {
          board_id: board.id,
          ids: [issue1.id, issue2.id, issue3.id],
          from_list_id: list1.id,
          to_list_id: list2.id,
          move_before_id: issue4.id,
          move_after_id: nil
        }
      end

      before do
        project.add_maintainer(user)
        project.add_guest(guest)
      end

      shared_examples 'move issues endpoint provider' do
        before do
          sign_in(signed_in_user)
        end

        it 'responds as expected' do
          put :bulk_move, params: move_issues_params
          expect(response).to have_gitlab_http_status(expected_status)

          if expected_status == 200
            expect(json_response).to include(
              'count' => move_issues_params[:ids].size,
              'success' => true
            )

            expect(json_response['issues'].pluck('id')).to match_array(move_issues_params[:ids])
          end
        end

        it 'moves issues as expected' do
          put :bulk_move, params: move_issues_params
          expect(response).to have_gitlab_http_status(expected_status)

          list_issues user: requesting_user, board: board, list: list2
          expect(response).to have_gitlab_http_status(:ok)

          expect(response).to match_response_schema('entities/issue_boards')

          responded_issues = json_response['issues']
          expect(responded_issues.length).to eq expected_issue_count

          ids_in_order = responded_issues.pluck('id')
          expect(ids_in_order).to eq(expected_issue_ids_in_order)
        end
      end

      context 'when items are moved to another list' do
        it_behaves_like 'move issues endpoint provider' do
          let(:signed_in_user) { user }
          let(:move_issues_params) { move_params }
          let(:requesting_user) { user }
          let(:expected_status) { 200 }
          let(:expected_issue_count) { 4 }
          let(:expected_issue_ids_in_order) { [issue4.id, issue1.id, issue2.id, issue3.id] }
        end
      end

      context 'when moving just one issue' do
        it_behaves_like 'move issues endpoint provider' do
          let(:signed_in_user) { user }
          let(:move_issues_params) do
            move_params.dup.tap do |hash|
              hash[:ids] = [issue2.id]
            end
          end

          let(:requesting_user) { user }
          let(:expected_status) { 200 }
          let(:expected_issue_count) { 2 }
          let(:expected_issue_ids_in_order) { [issue4.id, issue2.id] }
        end
      end

      context 'when user is not allowed to move issue' do
        it_behaves_like 'move issues endpoint provider' do
          let(:signed_in_user) { guest }
          let(:move_issues_params) do
            move_params.dup.tap do |hash|
              hash[:ids] = [issue2.id]
            end
          end

          let(:requesting_user) { user }
          let(:expected_status) { 403 }
          let(:expected_issue_count) { 1 }
          let(:expected_issue_ids_in_order) { [issue4.id] }
        end
      end

      context 'when issues should be moved visually above existing issue in list' do
        it_behaves_like 'move issues endpoint provider' do
          let(:signed_in_user) { user }
          let(:move_issues_params) do
            move_params.dup.tap do |hash|
              hash[:move_after_id] = issue4.id
              hash[:move_before_id] = nil
            end
          end

          let(:requesting_user) { user }
          let(:expected_status) { 200 }
          let(:expected_issue_count) { 4 }
          let(:expected_issue_ids_in_order) { [issue1.id, issue2.id, issue3.id, issue4.id] }
        end
      end

      context 'when destination list is empty' do
        before do
          # Remove issue from list
          issue4.labels -= [development]
          issue4.save!
        end

        it_behaves_like 'move issues endpoint provider' do
          let(:signed_in_user) { user }
          let(:move_issues_params) do
            move_params.dup.tap do |hash|
              hash[:move_before_id] = nil
            end
          end

          let(:requesting_user) { user }
          let(:expected_status) { 200 }
          let(:expected_issue_count) { 3 }
          let(:expected_issue_ids_in_order) { [issue1.id, issue2.id, issue3.id] }
        end
      end

      context 'when no position arguments are given' do
        it_behaves_like 'move issues endpoint provider' do
          let(:signed_in_user) { user }
          let(:move_issues_params) do
            move_params.dup.tap do |hash|
              hash[:move_before_id] = nil
            end
          end

          let(:requesting_user) { user }
          let(:expected_status) { 200 }
          let(:expected_issue_count) { 4 }
          let(:expected_issue_ids_in_order) { [issue1.id, issue2.id, issue3.id, issue4.id] }
        end
      end

      context 'when move_before_id and move_after_id are given' do
        let(:issue5) { create(:labeled_issue, project: project, labels: [development], author: user, relative_position: 90) }

        it_behaves_like 'move issues endpoint provider' do
          let(:signed_in_user) { user }
          let(:move_issues_params) do
            move_params.dup.tap do |hash|
              hash[:move_before_id] = issue5.id
              hash[:move_after_id] = issue4.id
            end
          end

          let(:requesting_user) { user }
          let(:expected_status) { 200 }
          let(:expected_issue_count) { 5 }
          let(:expected_issue_ids_in_order) { [issue5.id, issue1.id, issue2.id, issue3.id, issue4.id] }
        end
      end

      context 'when request contains too many issues' do
        it_behaves_like 'move issues endpoint provider' do
          let(:signed_in_user) { user }
          let(:move_issues_params) do
            move_params.dup.tap do |hash|
              hash[:ids] = (0..51).to_a
            end
          end

          let(:requesting_user) { user }
          let(:expected_status) { 422 }
          let(:expected_issue_count) { 1 }
          let(:expected_issue_ids_in_order) { [issue4.id] }
        end
      end

      context 'when request is malformed' do
        it_behaves_like 'move issues endpoint provider' do
          let(:signed_in_user) { user }
          let(:move_issues_params) do
            move_params.dup.tap do |hash|
              hash[:ids] = 'foobar'
            end
          end

          let(:requesting_user) { user }
          let(:expected_status) { 400 }
          let(:expected_issue_count) { 1 }
          let(:expected_issue_ids_in_order) { [issue4.id] }
        end
      end
    end

    def list_issues(user:, board:, list: nil)
      sign_in(user)

      params = {
        board_id: board.to_param,
        list_id: list.try(:to_param)
      }

      unless board.try(:parent).is_a?(Group)
        params[:namespace_id] = project.namespace.to_param
        params[:project_id] = project
      end

      get :index, params: params.compact
    end
  end

  describe 'POST create' do
    context 'with valid params' do
      it 'returns a successful 200 response' do
        create_issue user: user, board: board, list: list1, title: 'New issue'

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'returns the created issue' do
        create_issue user: user, board: board, list: list1, title: 'New issue'

        expect(response).to match_response_schema('entities/issue_board')
      end
    end

    context 'with invalid params' do
      context 'when title is nil' do
        it 'returns an unprocessable entity 422 response' do
          create_issue user: user, board: board, list: list1, title: nil

          expect(response).to have_gitlab_http_status(:unprocessable_entity)
        end
      end

      context 'when list does not belongs to project board' do
        it 'returns a not found 404 response' do
          list = create(:list)

          create_issue user: user, board: board, list: list, title: 'New issue'

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'with invalid board id' do
        it 'returns a not found 404 response' do
          create_issue user: user, board: non_existing_record_id, list: list1, title: 'New issue'

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'with invalid list id' do
        it 'returns a not found 404 response' do
          create_issue user: user, board: board, list: non_existing_record_id, title: 'New issue'

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'with guest user' do
      context 'in open list' do
        it 'returns a successful 200 response' do
          open_list = board.lists.create(list_type: :backlog)
          create_issue user: guest, board: board, list: open_list, title: 'New issue'

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'in label list' do
        it 'returns a forbidden 403 response' do
          create_issue user: guest, board: board, list: list1, title: 'New issue'

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    def create_issue(user:, board:, list:, title:)
      sign_in(user)

      post :create, params: {
                      board_id: board.to_param,
                      list_id: list.to_param,
                      issue: { title: title, project_id: project.id }
                    },
                    format: :json
    end
  end

  describe 'PATCH update' do
    let!(:issue) { create(:labeled_issue, project: project, labels: [planning]) }

    context 'with valid params' do
      it 'returns a successful 200 response' do
        move user: user, board: board, issue: issue, from_list_id: list1.id, to_list_id: list2.id

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'moves issue to the desired list' do
        move user: user, board: board, issue: issue, from_list_id: list1.id, to_list_id: list2.id

        expect(issue.reload.labels).to contain_exactly(development)
      end
    end

    context 'with invalid params' do
      it 'returns a unprocessable entity 422 response for invalid lists' do
        move user: user, board: board, issue: issue, from_list_id: nil, to_list_id: nil

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
      end

      it 'returns a not found 404 response for invalid board id' do
        move user: user, board: non_existing_record_id, issue: issue, from_list_id: list1.id, to_list_id: list2.id

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'returns a not found 404 response for invalid issue id' do
        move user: user, board: board, issue: double(id: non_existing_record_id), from_list_id: list1.id, to_list_id: list2.id

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with unauthorized user' do
      let(:guest) { create(:user) }

      before do
        project.add_guest(guest)
      end

      it 'returns a forbidden 403 response' do
        move user: guest, board: board, issue: issue, from_list_id: list1.id, to_list_id: list2.id

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    def move(user:, board:, issue:, from_list_id:, to_list_id:)
      sign_in(user)

      patch :update, params: {
                       namespace_id: project.namespace.to_param,
                       project_id: project.id,
                       board_id: board.to_param,
                       id: issue.id,
                       from_list_id: from_list_id,
                       to_list_id: to_list_id
                     },
                     format: :json
    end
  end
end
