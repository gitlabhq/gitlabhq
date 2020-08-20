# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::BoardListIssuesResolver do
  include GraphqlHelpers

  let_it_be(:user)          { create(:user) }
  let_it_be(:unauth_user)   { create(:user) }
  let_it_be(:user_project)  { create(:project, creator_id: user.id, namespace: user.namespace ) }
  let_it_be(:group)         { create(:group, :private) }

  shared_examples_for 'group and project board list issues resolver' do
    let!(:board) { create(:board, resource_parent: board_parent) }

    before do
      board_parent.add_developer(user)
    end

    # auth is handled by the parent object
    context 'when authorized' do
      let!(:list) { create(:list, board: board, label: label) }

      it 'returns the issues in the correct order' do
        issue1 = create(:issue, project: project, labels: [label], relative_position: 10)
        issue2 = create(:issue, project: project, labels: [label], relative_position: 12)
        issue3 = create(:issue, project: project, labels: [label], relative_position: 10)

        # by relative_position and then ID
        issues = resolve_board_list_issues.items

        expect(issues.map(&:id)).to eq [issue3.id, issue1.id, issue2.id]
      end
    end
  end

  describe '#resolve' do
    context 'when project boards' do
      let(:board_parent) { user_project }
      let!(:label) { create(:label, project: project, name: 'project label') }
      let(:project) { user_project }

      it_behaves_like 'group and project board list issues resolver'
    end

    context 'when group boards' do
      let(:board_parent) { group }
      let!(:label) { create(:group_label, group: group, name: 'group label') }
      let!(:project) { create(:project, :private, group: group) }

      it_behaves_like 'group and project board list issues resolver'
    end
  end

  def resolve_board_list_issues(args: {}, current_user: user)
    resolve(described_class, obj: list, args: args, ctx: { current_user: current_user })
  end
end
