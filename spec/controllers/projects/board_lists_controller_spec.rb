require 'spec_helper'

describe Projects::BoardListsController do
  let(:project) { create(:project_with_board) }
  let(:board)   { project.board }
  let(:user)    { create(:user) }

  before do
    project.team << [user, :master]
    sign_in(user)
  end

  describe 'POST #create' do
    context 'with valid params' do
      let(:label) { create(:label, project: project, name: 'Development') }

      it 'returns a successful 200 response' do
        create_board_list label_id: label.id

        expect(response).to have_http_status(200)
      end

      it 'returns the created list' do
        create_board_list label_id: label.id

        expect(response).to match_response_schema('list')
      end
    end

    context 'with invalid params' do
      it 'returns an error' do
        create_board_list label_id: nil

        parsed_response = JSON.parse(response.body)

        expect(parsed_response['label']).to contain_exactly "can't be blank"
        expect(response).to have_http_status(422)
      end
    end

    def create_board_list(label_id:)
      post :create, namespace_id: project.namespace.to_param,
                    project_id: project.to_param,
                    list: { label_id: label_id },
                    format: :json
    end
  end

  describe 'PATCH #update' do
    let!(:planning)    { create(:list, board: board, position: 0) }
    let!(:development) { create(:list, board: board, position: 1) }

    context 'with valid position' do
      it 'returns a successful 200 response' do
        move list: planning, position: 1

        expect(response).to have_http_status(200)
      end

      it 'moves the list to the desired position' do
        move list: planning, position: 1

        expect(planning.reload.position).to eq 1
      end
    end

    context 'with invalid position' do
      it 'returns a unprocessable entity 422 response' do
        move list: planning, position: 6

        expect(response).to have_http_status(422)
      end
    end

    context 'with invalid list id' do
      it 'returns a not found 404 response' do
        move list: 999, position: 1

        expect(response).to have_http_status(404)
      end
    end

    def move(list:, position:)
      patch :update, namespace_id: project.namespace.to_param,
                     project_id: project.to_param,
                     id: list.to_param,
                     list: { position: position },
                     format: :json
    end
  end

  describe 'DELETE #destroy' do
    context 'with valid list id' do
      let!(:planning) { create(:list, board: board, position: 0) }

      it 'returns a successful 200 response' do
        remove_board_list list: planning

        expect(response).to have_http_status(200)
      end

      it 'removes list from board' do
        expect { remove_board_list list: planning }.to change(board.lists, :size).by(-1)
      end
    end

    context 'with invalid list id' do
      it 'returns a not found 404 response' do
        remove_board_list list: 999

        expect(response).to have_http_status(404)
      end
    end

    def remove_board_list(list:)
      delete :destroy, namespace_id: project.namespace.to_param,
                       project_id: project.to_param,
                       id: list.to_param,
                       format: :json
    end
  end
end
