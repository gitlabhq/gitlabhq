# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Boards::Issues::IssueMoveList do
  include GraphqlHelpers

  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:board) { create(:board, group: group) }
  let_it_be(:user)  { create(:user, maintainer_of: group) }
  let_it_be(:guest) { create(:user, guest_of: group) }
  let_it_be(:development) { create(:label, project: project, name: 'Development') }
  let_it_be(:testing) { create(:label, project: project, name: 'Testing') }
  let_it_be(:list1)   { create(:list, board: board, label: development, position: 0) }
  let_it_be(:list2)   { create(:list, board: board, label: testing, position: 1) }
  let_it_be(:issue1) { create(:labeled_issue, project: project, labels: [development]) }
  let_it_be(:existing_issue1) { create(:labeled_issue, project: project, labels: [testing], relative_position: 10) }
  let_it_be(:existing_issue2) { create(:labeled_issue, project: project, labels: [testing], relative_position: 50) }

  let(:current_ctx) { { current_user: user } }
  let(:params) { { board_id: global_id_of(board), project_path: project.full_path, iid: issue1.iid.to_s } }
  let(:move_params) do
    {
      from_list_id: list1.id,
      to_list_id: list2.id,
      move_before_id: existing_issue2.id,
      move_after_id: existing_issue1.id
    }
  end

  describe '#resolve' do
    subject do
      sync(resolve(described_class, args: params.merge(move_params), ctx: current_ctx))
    end

    %i[from_list_id to_list_id].each do |arg_name|
      context "when we only pass #{arg_name}" do
        let(:move_params) { { arg_name => list1.id } }

        it 'generates an error' do
          expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ArgumentError, 'Both fromListId and toListId must be present') do
            subject
          end
        end
      end
    end

    context 'when required arguments are missing' do
      let(:move_params) { {} }

      it 'generates an error' do
        expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ArgumentError, 'At least one of the arguments fromListId, toListId, positionInList, moveAfterId, or moveBeforeId is required') do
          subject
        end
      end
    end

    context 'when the board ID is wrong' do
      before do
        params[:board_id] = global_id_of(project)
      end

      it 'raises an error' do
        expect(subject).to be_a(::GraphQL::CoercionError)
        expect(subject.message).to eq("\"#{params[:board_id]}\" does not represent an instance of Board")
      end
    end

    context 'when positionInList is given' do
      let(:move_params) { { from_list_id: list1.id, to_list_id: list2.id, position_in_list: 0 } }

      context 'when fromListId and toListId are missing' do
        let(:move_params) { { position_in_list: 0 } }

        it 'generates an error' do
          expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ArgumentError, 'Both fromListId and toListId are required when positionInList is given') do
            subject
          end
        end
      end

      context 'when move_before_id is also given' do
        let(:move_params) { { from_list_id: list1.id, to_list_id: list2.id, position_in_list: 0, move_before_id: 1 } }

        it 'generates an error' do
          expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ArgumentError, 'positionInList is mutually exclusive with any of moveBeforeId or moveAfterId') do
            subject
          end
        end
      end

      context 'when move_after_id is also given' do
        let(:move_params) { { from_list_id: list1.id, to_list_id: list2.id, position_in_list: 0, move_after_id: 1 } }

        it 'generates an error' do
          expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ArgumentError, 'positionInList is mutually exclusive with any of moveBeforeId or moveAfterId') do
            subject
          end
        end
      end

      context 'when position_in_list is invalid' do
        let(:move_params) { { from_list_id: list1.id, to_list_id: list2.id, position_in_list: -5 } }

        it 'generates an error' do
          expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ArgumentError, "positionInList must be >= 0 or #{Boards::Issues::MoveService::LIST_END_POSITION}") do
            subject
          end
        end
      end
    end

    context 'when user have access to resources' do
      it 'moves and repositions issue' do
        subject

        expect(issue1.reload.labels).to eq([testing])
        expect(issue1.relative_position).to be < existing_issue2.relative_position
        expect(issue1.relative_position).to be > existing_issue1.relative_position
      end
    end

    context 'when user cannot update issue' do
      let(:current_ctx) { { current_user: guest } }

      specify do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end
  end
end
