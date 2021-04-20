# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Multiple Issue Boards', :js do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:planning) { create(:label, project: project, name: 'Planning') }
  let_it_be(:board) { create(:board, name: 'board1', project: project) }
  let_it_be(:board2) { create(:board, name: 'board2', project: project) }

  let(:parent) { project }
  let(:boards_path) { project_boards_path(project) }

  it_behaves_like 'multiple issue boards'
end
