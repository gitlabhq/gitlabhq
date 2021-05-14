# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Issue boards sidebar labels select', :js do
  include BoardHelpers

  include_context 'labels from nested groups and projects'

  let(:card) { find('.board:nth-child(1)').first('[data-testid="board_card"]') }

  context 'group boards' do
    context 'in the top-level group board' do
      let_it_be(:group_board) { create(:board, group: group) }
      let_it_be(:board_list) { create(:backlog_list, board: group_board) }

      before do
        load_board group_board_path(group, group_board)
      end

      context 'selecting an issue from a direct descendant project' do
        let_it_be(:project_issue) { create(:issue, project: project) }

        include_examples 'an issue from a direct descendant project is selected'
      end

      context "selecting an issue from a subgroup's project" do
        let_it_be(:subproject_issue) { create(:issue, project: subproject) }

        include_examples "an issue from a subgroup's project is selected"
      end
    end
  end
end
