# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::BoardsController do
  let_it_be(:group) { create(:group) }
  let_it_be(:user)  { create(:user, maintainer_of: group) }

  before do
    sign_in(user)
  end

  describe 'GET index' do
    it 'creates a new board when group does not have one' do
      expect { list_boards }.to change(group.boards, :count).by(1)
    end

    context 'when format is HTML' do
      it 'renders template' do
        list_boards

        expect(response).to render_template :index
        expect(response.media_type).to eq 'text/html'
      end

      context 'with unauthorized user' do
        before do
          expect(Ability).to receive(:allowed?).with(user, :log_in, :global).and_call_original
          allow(Ability).to receive(:allowed?).with(user, :read_cross_project, :global).and_return(true)
          allow(Ability).to receive(:allowed?).with(user, :read_group, group).and_return(true)
          allow(Ability).to receive(:allowed?).with(user, :read_issue_board, group).and_return(false)
        end

        it 'returns a not found 404 response' do
          list_boards

          expect(response).to have_gitlab_http_status(:not_found)
          expect(response.media_type).to eq 'text/html'
        end
      end

      context 'when user is signed out' do
        let(:group) { create(:group, :public) }

        it 'renders template' do
          sign_out(user)

          board = create(:board, group: group)
          create(:board_group_recent_visit, group: board.group, board: board, user: user)

          list_boards

          expect(response).to render_template :index
          expect(response.media_type).to eq 'text/html'
        end
      end
    end

    it_behaves_like 'disabled when using an external authorization service' do
      subject { list_boards }
    end

    def list_boards
      get :index, params: { group_id: group }
    end
  end

  describe 'GET show' do
    let_it_be(:board) { create(:board, group: group) }

    context 'when format is HTML' do
      it 'renders template' do
        expect { read_board board: board }.to change(BoardGroupRecentVisit, :count).by(1)

        expect(response).to render_template :show
        expect(response.media_type).to eq 'text/html'
      end

      context 'with unauthorized user' do
        before do
          expect(Ability).to receive(:allowed?).with(user, :log_in, :global).and_call_original
          allow(Ability).to receive(:allowed?).with(user, :read_cross_project, :global).and_return(true)
          allow(Ability).to receive(:allowed?).with(user, :read_group, group).and_return(true)
          allow(Ability).to receive(:allowed?).with(user, :read_issue_board, group).and_return(false)
        end

        it 'returns a not found 404 response' do
          read_board board: board

          expect(response).to have_gitlab_http_status(:not_found)
          expect(response.media_type).to eq 'text/html'
        end
      end

      context 'when user is signed out' do
        let(:public_board) { create(:board, group: create(:group, :public)) }

        it 'does not save visit' do
          sign_out(user)

          expect { read_board board: public_board }.to not_change(BoardGroupRecentVisit, :count)

          expect(response).to render_template :show
          expect(response.media_type).to eq 'text/html'
        end
      end
    end

    context 'when board does not belong to group' do
      it 'returns a not found 404 response' do
        another_board = create(:board)

        get :show, params: { group_id: group, id: another_board.to_param }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    it_behaves_like 'disabled when using an external authorization service' do
      subject { read_board board: board }
    end

    def read_board(board:)
      get :show, params: { group_id: board.group, id: board.to_param }
    end
  end
end
