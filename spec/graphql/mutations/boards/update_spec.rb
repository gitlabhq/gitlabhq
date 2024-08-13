# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Boards::Update, feature_category: :api do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:board) { create(:board, project: project) }

  let(:mutation) { described_class.new(object: nil, context: query_context, field: nil) }
  let(:mutated_board) { subject[:board] }

  let(:mutation_params) do
    {
      id: board.to_global_id,
      hide_backlog_list: true,
      hide_closed_list: false
    }
  end

  subject { mutation.resolve(**mutation_params) }

  specify { expect(described_class).to require_graphql_authorizations(:admin_issue_board) }

  describe '#resolve' do
    context 'when the user cannot admin the board' do
      it 'raises an error' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when user can update board' do
      before do
        board.resource_parent.add_reporter(current_user)
      end

      it 'updates board with correct values' do
        expected_attributes = {
          hide_backlog_list: true,
          hide_closed_list: false
        }

        subject

        expect(board.reload).to have_attributes(expected_attributes)
      end
    end
  end
end
