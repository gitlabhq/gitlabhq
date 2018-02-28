require 'spec_helper'

describe Boards::ListsController do
  let(:project) { create(:project) }
  let(:board)   { create(:board, project: project) }
  let(:user)    { create(:user) }
  let(:guest)   { create(:user) }

  before do
    project.add_master(user)
    project.add_guest(guest)
  end

  describe 'GET index' do
    it 'returns a successful 200 response' do
      read_board_list user: user, board: board

      expect(response).to have_gitlab_http_status(200)
      expect(response.content_type).to eq 'application/json'
    end

    it 'returns a list of board lists' do
      create(:list, board: board)

      read_board_list user: user, board: board

      parsed_response = JSON.parse(response.body)

      expect(response).to match_response_schema('lists')
      expect(parsed_response.length).to eq 3
    end

    context 'with unauthorized user' do
      before do
        allow(Ability).to receive(:allowed?).with(user, :read_project, project).and_return(true)
        allow(Ability).to receive(:allowed?).with(user, :read_list, project).and_return(false)
      end

      it 'returns a forbidden 403 response' do
        read_board_list user: user, board: board

        expect(response).to have_gitlab_http_status(403)
      end
    end

    def read_board_list(user:, board:)
      sign_in(user)

      get :index, namespace_id: project.namespace.to_param,
                  project_id: project,
                  board_id: board.to_param,
                  format: :json
    end
  end

  describe 'POST create' do
    context 'with valid params' do
      let(:label) { create(:label, project: project, name: 'Development') }

      it 'returns a successful 200 response' do
        create_board_list user: user, board: board, label_id: label.id

        expect(response).to have_gitlab_http_status(200)
      end

      it 'returns the created list' do
        create_board_list user: user, board: board, label_id: label.id

        expect(response).to match_response_schema('list')
      end
    end

    context 'with invalid params' do
      context 'when label is nil' do
        it 'returns a not found 404 response' do
          create_board_list user: user, board: board, label_id: nil

          expect(response).to have_gitlab_http_status(404)
        end
      end

      context 'when label that does not belongs to project' do
        it 'returns a not found 404 response' do
          label = create(:label, name: 'Development')

          create_board_list user: user, board: board, label_id: label.id

          expect(response).to have_gitlab_http_status(404)
        end
      end
    end

    context 'with unauthorized user' do
      it 'returns a forbidden 403 response' do
        label = create(:label, project: project, name: 'Development')

        create_board_list user: guest, board: board, label_id: label.id

        expect(response).to have_gitlab_http_status(403)
      end
    end

    def create_board_list(user:, board:, label_id:)
      sign_in(user)

      post :create, namespace_id: project.namespace.to_param,
                    project_id: project,
                    board_id: board.to_param,
                    list: { label_id: label_id },
                    format: :json
    end
  end

  describe 'PATCH update' do
    let!(:planning)    { create(:list, board: board, position: 0) }
    let!(:development) { create(:list, board: board, position: 1) }

    context 'with valid position' do
      it 'returns a successful 200 response' do
        move user: user, board: board, list: planning, position: 1

        expect(response).to have_gitlab_http_status(200)
      end

      it 'moves the list to the desired position' do
        move user: user, board: board, list: planning, position: 1

        expect(planning.reload.position).to eq 1
      end
    end

    context 'with invalid position' do
      it 'returns an unprocessable entity 422 response' do
        move user: user, board: board, list: planning, position: 6

        expect(response).to have_gitlab_http_status(422)
      end
    end

    context 'with invalid list id' do
      it 'returns a not found 404 response' do
        move user: user, board: board, list: 999, position: 1

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'with unauthorized user' do
      it 'returns a forbidden 403 response' do
        move user: guest, board: board, list: planning, position: 6

        expect(response).to have_gitlab_http_status(403)
      end
    end

    def move(user:, board:, list:, position:)
      sign_in(user)

      patch :update, namespace_id: project.namespace.to_param,
                     project_id: project,
                     board_id: board.to_param,
                     id: list.to_param,
                     list: { position: position },
                     format: :json
    end
  end

  describe 'DELETE destroy' do
    let!(:planning) { create(:list, board: board, position: 0) }

    context 'with valid list id' do
      it 'returns a successful 200 response' do
        remove_board_list user: user, board: board, list: planning

        expect(response).to have_gitlab_http_status(200)
      end

      it 'removes list from board' do
        expect { remove_board_list user: user, board: board, list: planning }.to change(board.lists, :size).by(-1)
      end
    end

    context 'with invalid list id' do
      it 'returns a not found 404 response' do
        remove_board_list user: user, board: board, list: 999

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'with unauthorized user' do
      it 'returns a forbidden 403 response' do
        remove_board_list user: guest, board: board, list: planning

        expect(response).to have_gitlab_http_status(403)
      end
    end

    def remove_board_list(user:, board:, list:)
      sign_in(user)

      delete :destroy, namespace_id: project.namespace.to_param,
                       project_id: project,
                       board_id: board.to_param,
                       id: list.to_param,
                       format: :json
    end
  end

  describe 'POST generate' do
    context 'when board lists is empty' do
      it 'returns a successful 200 response' do
        generate_default_lists user: user, board: board

        expect(response).to have_gitlab_http_status(200)
      end

      it 'returns the defaults lists' do
        generate_default_lists user: user, board: board

        expect(response).to match_response_schema('lists')
      end
    end

    context 'when board lists is not empty' do
      it 'returns an unprocessable entity 422 response' do
        create(:list, board: board)

        generate_default_lists user: user, board: board

        expect(response).to have_gitlab_http_status(422)
      end
    end

    context 'with unauthorized user' do
      it 'returns a forbidden 403 response' do
        generate_default_lists user: guest, board: board

        expect(response).to have_gitlab_http_status(403)
      end
    end

    def generate_default_lists(user:, board:)
      sign_in(user)

      post :generate, namespace_id: project.namespace.to_param,
                      project_id: project,
                      board_id: board.to_param,
                      format: :json
    end
  end
end
