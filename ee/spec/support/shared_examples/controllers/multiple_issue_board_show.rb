require 'spec_helper'

shared_examples 'multiple issue boards show' do
  let!(:board1) { create(:board, parent: parent, name: 'b') }
  let!(:board2) { create(:board, parent: parent, name: 'a') }

  context 'when multiple issue boards is enabled' do
    it 'let user view any board from parent' do
      [board1, board2].each do |board|
        show(board)

        expect(response).to have_gitlab_http_status(200)
        expect(assigns(:board)).to eq(board)
      end
    end
  end

  context 'when multiple issue boards is disabled' do
    before do
      stub_licensed_features(multiple_project_issue_boards: false, multiple_group_issue_boards: false)
    end

    it 'let user view the default shown board' do
      show(board2)

      expect(response).to have_gitlab_http_status(200)
      expect(assigns(:board)).to eq(board2)
    end

    it 'renders 404 when board is not the default' do
      show(board1)

      expect(response).to have_gitlab_http_status(404)
    end
  end

  def show(board)
    params = {}
    params[:id] = board.to_param

    if board.group_board?
      params[:group_id] = parent
    else
      params.merge!(namespace_id: parent.namespace, project_id: parent)
    end

    get :show, params
  end
end
