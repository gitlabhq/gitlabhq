require 'spec_helper'

describe API::Boards do
  set(:user) { create(:user) }
  set(:board_parent) { create(:project, :public, creator_id: user.id, namespace: user.namespace ) }
  set(:milestone) { create(:milestone, project: board_parent) }
  set(:board) { create(:board, project: board_parent, milestone: milestone) }

  it_behaves_like 'multiple and scoped issue boards', "/projects/:id/boards"

  describe 'POST /projects/:id/boards/:board_id/lists' do
    let(:url) { "/projects/#{board_parent.id}/boards/#{board.id}/lists" }

    it_behaves_like 'milestone board list'
    it_behaves_like 'assignee board list'
  end
end
