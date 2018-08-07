require 'spec_helper'

describe Boards::MilestonesController do
  let(:project) { create(:project) }
  let(:board) { create(:board, project: project) }
  let(:user)  { create(:user) }

  before do
    create(:milestone, project: project)

    project.add_maintainer(user)
    sign_in(user)
  end

  describe 'GET index' do
    it 'returns a list of all milestones of board parent' do
      get :index, board_id: board.to_param, format: :json

      parsed_response = JSON.parse(response.body)

      expect(response).to have_gitlab_http_status(200)
      expect(response.content_type).to eq('application/json')
      expect(parsed_response).to all(match_schema('entities/milestone', dir: 'ee'))
      expect(parsed_response.size).to eq(1)
    end
  end
end
