# frozen_string_literal: true

require 'spec_helper'

describe 'Multiple Issue Boards', :js do
  set(:user) { create(:user) }
  set(:project) { create(:project, :public) }
  set(:planning) { create(:label, project: project, name: 'Planning') }
  set(:board) { create(:board, name: 'board1', project: project) }
  set(:board2) { create(:board, name: 'board2', project: project) }
  let(:parent) { project }
  let(:boards_path) { project_boards_path(project) }

  it_behaves_like 'multiple issue boards'
end
