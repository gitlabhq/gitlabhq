# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::BoardsController do
  let_it_be(:project) { create(:project) }
  let_it_be(:user)    { create(:user, maintainer_of: project) }

  before do
    sign_in(user)
  end

  describe 'GET index' do
    it 'creates a new project board when project does not have one' do
      expect { list_boards }.to change(project.boards, :count).by(1)
    end

    it 'renders template' do
      list_boards

      expect(response).to render_template :index
      expect(response.media_type).to eq 'text/html'
    end

    context 'when there are recently visited boards' do
      let_it_be(:boards) { create_list(:board, 3, resource_parent: project) }

      before_all do
        visit_board(boards[2], Time.current + 1.minute)
        visit_board(boards[0], Time.current + 2.minutes)
        visit_board(boards[1], Time.current + 5.minutes)
      end

      it 'redirects to latest visited board' do
        list_boards

        expect(response).to redirect_to(
          namespace_project_board_path(namespace_id: project.namespace, project_id: project, id: boards[1].id)
        )
      end

      def visit_board(board, time)
        create(:board_project_recent_visit, project: project, board: board, user: user, updated_at: time)
      end
    end

    context 'with unauthorized user' do
      before do
        expect(Ability).to receive(:allowed?).with(user, :log_in, :global).and_call_original
        allow(Ability).to receive(:allowed?).with(user, :read_project, project).and_return(true)
        allow(Ability).to receive(:allowed?).with(user, :read_issue_board, project).and_return(false)
      end

      it 'returns a not found 404 response' do
        list_boards

        expect(response).to have_gitlab_http_status(:not_found)
        expect(response.media_type).to eq 'text/html'
      end
    end

    context 'when user is signed out' do
      let(:project) { create(:project, :public) }

      it 'renders template' do
        sign_out(user)

        board = create(:board, project: project)
        create(:board_project_recent_visit, project: board.project, board: board, user: user)

        list_boards

        expect(response).to render_template :index
        expect(response.media_type).to eq 'text/html'
      end
    end

    context 'issues are disabled' do
      let(:project) { create(:project, :issues_disabled) }

      it 'returns a not found 404 response' do
        list_boards

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    it_behaves_like 'unauthorized when external service denies access' do
      subject { list_boards }
    end

    def list_boards
      get :index, params: {
                    namespace_id: project.namespace,
                    project_id: project
                  }
    end
  end

  describe 'GET show' do
    let_it_be(:board) { create(:board, project: project) }

    context 'when format is HTML' do
      it 'renders template' do
        expect { read_board board: board }.to change(BoardProjectRecentVisit, :count).by(1)

        expect(response).to render_template :show
        expect(response.media_type).to eq 'text/html'
      end

      context 'with unauthorized user' do
        before do
          expect(Ability).to receive(:allowed?).with(user, :log_in, :global).and_call_original
          allow(Ability).to receive(:allowed?).with(user, :read_project, project).and_return(true)
          allow(Ability).to receive(:allowed?).with(user, :read_issue_board, project).and_return(false)
        end

        it 'returns a not found 404 response' do
          read_board board: board

          expect(response).to have_gitlab_http_status(:not_found)
          expect(response.media_type).to eq 'text/html'
        end
      end

      context 'when user is signed out' do
        let(:public_board) { create(:board, project: create(:project, :public)) }

        it 'does not save visit' do
          sign_out(user)

          expect { read_board board: public_board }.to change(BoardProjectRecentVisit, :count).by(0)

          expect(response).to render_template :show
          expect(response.media_type).to eq 'text/html'
        end
      end
    end

    context 'when board does not belong to project' do
      it 'returns a not found 404 response' do
        another_board = create(:board)

        get :show, params: { namespace_id: project.namespace, project_id: project, id: another_board.to_param }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    def read_board(board:)
      get :show, params: { namespace_id: board.project.namespace, project_id: board.project, id: board.to_param }
    end
  end
end
