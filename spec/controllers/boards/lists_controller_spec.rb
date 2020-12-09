# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Boards::ListsController do
  let(:project) { create(:project) }
  let(:board)   { create(:board, project: project) }
  let(:user)    { create(:user) }
  let(:guest)   { create(:user) }

  before do
    project.add_maintainer(user)
    project.add_guest(guest)
  end

  describe 'GET index' do
    before do
      create(:list, board: board)
    end

    it 'returns a successful 200 response' do
      read_board_list user: user, board: board

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.media_type).to eq 'application/json'
    end

    it 'returns a list of board lists' do
      read_board_list user: user, board: board

      expect(response).to match_response_schema('lists')
      expect(json_response.length).to eq 3
    end

    context 'when another user has list preferences' do
      before do
        board.lists.first.update_preferences_for(guest, collapsed: true)
      end

      it 'returns the complete list of board lists' do
        read_board_list user: user, board: board

        expect(json_response.length).to eq 3
      end
    end

    context 'with unauthorized user' do
      let(:unauth_user) { create(:user) }

      it 'returns a forbidden 403 response' do
        read_board_list user: unauth_user, board: board

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    def read_board_list(user:, board:)
      sign_in(user)

      get :index, params: {
                    namespace_id: project.namespace.to_param,
                    project_id: project,
                    board_id: board.to_param
                  },
                  format: :json
    end
  end

  describe 'POST create' do
    context 'with valid params' do
      let(:label) { create(:label, project: project, name: 'Development') }

      it 'returns a successful 200 response' do
        create_board_list user: user, board: board, label_id: label.id

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'returns the created list' do
        create_board_list user: user, board: board, label_id: label.id

        expect(response).to match_response_schema('list')
      end
    end

    context 'with invalid params' do
      context 'when label is nil' do
        it 'returns an unprocessable entity 422 response' do
          create_board_list user: user, board: board, label_id: nil

          expect(response).to have_gitlab_http_status(:unprocessable_entity)
          expect(json_response['errors']).to eq(['Label not found'])
        end
      end

      context 'when label that does not belongs to project' do
        it 'returns an unprocessable entity 422 response' do
          label = create(:label, name: 'Development')

          create_board_list user: user, board: board, label_id: label.id

          expect(response).to have_gitlab_http_status(:unprocessable_entity)
          expect(json_response['errors']).to eq(['Label not found'])
        end
      end
    end

    context 'with unauthorized user' do
      it 'returns a forbidden 403 response' do
        label = create(:label, project: project, name: 'Development')

        create_board_list user: guest, board: board, label_id: label.id

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    def create_board_list(user:, board:, label_id:)
      sign_in(user)

      post :create, params: {
                      namespace_id: project.namespace.to_param,
                      project_id: project,
                      board_id: board.to_param,
                      list: { label_id: label_id }
                    },
                    format: :json
    end
  end

  describe 'PATCH update' do
    let!(:planning)    { create(:list, board: board, position: 0) }
    let!(:development) { create(:list, board: board, position: 1) }

    context 'with valid position' do
      it 'returns a successful 200 response' do
        move user: user, board: board, list: planning, position: 1

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'moves the list to the desired position' do
        move user: user, board: board, list: planning, position: 1

        expect(planning.reload.position).to eq 1
      end
    end

    context 'with invalid position' do
      it 'returns an unprocessable entity 422 response' do
        move user: user, board: board, list: planning, position: 6

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
      end
    end

    context 'with invalid list id' do
      it 'returns a not found 404 response' do
        move user: user, board: board, list: non_existing_record_id, position: 1

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with unauthorized user' do
      it 'returns a 422 unprocessable entity response' do
        move user: guest, board: board, list: planning, position: 6

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
      end
    end

    context 'with collapsed preference' do
      it 'saves collapsed preference for user' do
        save_setting user: user, board: board, list: planning, setting: { collapsed: true }

        expect(planning.preferences_for(user).collapsed).to eq(true)
        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'saves not collapsed preference for user' do
        save_setting user: user, board: board, list: planning, setting: { collapsed: false }

        expect(planning.preferences_for(user).collapsed).to eq(false)
        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'with a list_type other than :label' do
      let!(:closed) { create(:closed_list, board: board, position: 2) }

      it 'saves collapsed preference for user' do
        save_setting user: user, board: board, list: closed, setting: { collapsed: true }

        expect(closed.preferences_for(user).collapsed).to eq(true)
        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'saves not collapsed preference for user' do
        save_setting user: user, board: board, list: closed, setting: { collapsed: false }

        expect(closed.preferences_for(user).collapsed).to eq(false)
        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    def move(user:, board:, list:, position:)
      sign_in(user)

      params = { namespace_id: project.namespace.to_param,
                 project_id: project,
                 board_id: board.to_param,
                 id: list.to_param,
                 list: { position: position },
                 format: :json }

      patch :update, params: params, as: :json
    end

    def save_setting(user:, board:, list:, setting: {})
      sign_in(user)

      params = { namespace_id: project.namespace.to_param,
                 project_id: project,
                 board_id: board.to_param,
                 id: list.to_param,
                 list: setting,
                 format: :json }

      patch :update, params: params, as: :json
    end
  end

  describe 'DELETE destroy' do
    let!(:planning) { create(:list, board: board, position: 0) }

    context 'with valid list id' do
      it 'returns a successful 200 response' do
        remove_board_list user: user, board: board, list: planning

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'removes list from board' do
        expect { remove_board_list user: user, board: board, list: planning }.to change(board.lists, :size).by(-1)
      end
    end

    context 'with invalid list id' do
      it 'returns a not found 404 response' do
        remove_board_list user: user, board: board, list: non_existing_record_id

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with unauthorized user' do
      it 'returns a forbidden 403 response' do
        remove_board_list user: guest, board: board, list: planning

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'with an error service response' do
      it 'returns an unprocessable entity response' do
        allow(Boards::Lists::DestroyService).to receive(:new)
          .and_return(double(execute: ServiceResponse.error(message: 'error')))

        remove_board_list user: user, board: board, list: planning

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
      end
    end

    def remove_board_list(user:, board:, list:)
      sign_in(user)

      delete :destroy, params: {
                         namespace_id: project.namespace.to_param,
                         project_id: project,
                         board_id: board.to_param,
                         id: list.to_param
                       },
                       format: :json
    end
  end

  describe 'POST generate' do
    context 'when board lists is empty' do
      it 'returns a successful 200 response' do
        generate_default_lists user: user, board: board

        expect(response).to have_gitlab_http_status(:ok)
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

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
      end
    end

    context 'with unauthorized user' do
      it 'returns a forbidden 403 response' do
        generate_default_lists user: guest, board: board

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    def generate_default_lists(user:, board:)
      sign_in(user)

      post :generate, params: {
                        namespace_id: project.namespace.to_param,
                        project_id: project,
                        board_id: board.to_param
                      },
                      format: :json
    end
  end
end
