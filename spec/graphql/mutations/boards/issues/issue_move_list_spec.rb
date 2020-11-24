# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Boards::Issues::IssueMoveList do
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:board) { create(:board, group: group) }
  let_it_be(:user)  { create(:user) }
  let_it_be(:guest) { create(:user) }
  let_it_be(:development) { create(:label, project: project, name: 'Development') }
  let_it_be(:testing) { create(:label, project: project, name: 'Testing') }
  let_it_be(:list1)   { create(:list, board: board, label: development, position: 0) }
  let_it_be(:list2)   { create(:list, board: board, label: testing, position: 1) }
  let_it_be(:issue1) { create(:labeled_issue, project: project, labels: [development]) }
  let_it_be(:existing_issue1) { create(:labeled_issue, project: project, labels: [testing], relative_position: 10) }
  let_it_be(:existing_issue2) { create(:labeled_issue, project: project, labels: [testing], relative_position: 50) }

  let(:current_user) { user }
  let(:mutation) { described_class.new(object: nil, context: { current_user: current_user }, field: nil) }
  let(:params) { { board: board, project_path: project.full_path, iid: issue1.iid } }
  let(:move_params) do
    {
      from_list_id: list1.id,
      to_list_id: list2.id,
      move_before_id: existing_issue2.id,
      move_after_id: existing_issue1.id
    }
  end

  before_all do
    group.add_maintainer(user)
    group.add_guest(guest)
  end

  subject do
    mutation.resolve(**params.merge(move_params))
  end

  describe '#ready?' do
    it 'raises an error if required arguments are missing' do
      expect { mutation.ready?(**params) }
        .to raise_error(Gitlab::Graphql::Errors::ArgumentError, "At least one of the arguments " \
        "fromListId, toListId, afterId or beforeId is required")
    end

    it 'raises an error if only one of fromListId and toListId is present' do
      expect { mutation.ready?(**params.merge(from_list_id: list1.id)) }
        .to raise_error(Gitlab::Graphql::Errors::ArgumentError,
          'Both fromListId and toListId must be present'
        )
    end
  end

  describe '#resolve' do
    context 'when user have access to resources' do
      it 'moves and repositions issue' do
        subject

        expect(issue1.reload.labels).to eq([testing])
        expect(issue1.relative_position).to be < existing_issue2.relative_position
        expect(issue1.relative_position).to be > existing_issue1.relative_position
      end
    end

    context 'when user have no access to resources' do
      shared_examples 'raises a resource not available error' do
        it { expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable) }
      end

      context 'when user cannot update issue' do
        let(:current_user) { guest }

        it_behaves_like 'raises a resource not available error'
      end

      context 'when user cannot access board' do
        let(:board) { create(:board, group: create(:group, :private)) }

        it_behaves_like 'raises a resource not available error'
      end

      context 'when passing board_id as nil' do
        let(:board) { nil }

        it_behaves_like 'raises a resource not available error'
      end
    end
  end
end
