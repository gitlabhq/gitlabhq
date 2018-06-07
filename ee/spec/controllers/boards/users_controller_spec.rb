require 'spec_helper'

describe Boards::UsersController do
  let(:group) { create(:group) }
  let(:board) { create(:board, group: group) }
  let(:guest) { create(:user) }
  let(:user)  { create(:user) }

  before do
    group.add_master(user)
    group.add_guest(guest)

    sign_in(user)
  end

  describe 'GET index' do
    it 'returns a list of all members of board parent' do
      get :index, namespace_id: group.to_param,
                  board_id: board.to_param,
                  format: :json

      parsed_response = JSON.parse(response.body)

      expect(response).to have_gitlab_http_status(200)
      expect(response.content_type).to eq 'application/json'
      expect(parsed_response).to all(match_schema('entities/user'))
      expect(parsed_response.length).to eq 2
    end
  end
end
