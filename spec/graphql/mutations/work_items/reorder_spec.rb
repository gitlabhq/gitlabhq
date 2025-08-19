# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::WorkItems::Reorder, feature_category: :team_planning do
  include GraphqlHelpers
  using RSpec::Parameterized::TableSyntax

  let_it_be(:project) { create(:project) }
  let_it_be(:current_user) { create(:user, developer_of: project) }
  let_it_be(:item1, reload: true) { create(:work_item, :issue, project: project, relative_position: 10) }
  let_it_be(:item2, reload: true) { create(:work_item, :issue, project: project, relative_position: 20) }

  subject(:mutation) { described_class.new(object: nil, context: query_context, field: nil) }

  describe '#ready?' do
    context 'with invalid arguments' do
      it 'raises an error' do
        expect { mutation.ready? }
          .to raise_error('At least one of move_before_id and move_after_id are required')
      end
    end

    context 'with valid arguments' do
      where(:move_before, :move_after, :expected_result) do
        nil | ref(:item2) | true
        ref(:item2) | nil | true
      end

      with_them do
        specify do
          ready_result = mutation.ready?(
            move_before_id: move_before&.id,
            move_after_id: move_after&.id
          )

          expect(ready_result).to be(expected_result)
        end
      end
    end
  end

  describe '#resolve' do
    context 'when it fails to move' do
      specify do
        result = mutation.resolve(
          id: item2.to_gid,
          move_before_id: non_existing_record_id
        )

        expect(result[:errors]).to eq(["Work item not found"])
        expect(result[:work_item]&.relative_position).to be(item2.relative_position)
      end
    end

    context 'when moving it before other item' do
      specify do
        result = mutation.resolve(
          id: item1.to_gid,
          move_before_id: item2.id
        )

        expect(result[:errors]).to be_empty
        expect(result[:work_item].relative_position).to be > item2.relative_position
      end
    end

    context 'when moving it after other item' do
      specify do
        result = mutation.resolve(
          id: item2.to_gid,
          move_after_id: item1.id
        )

        expect(result[:errors]).to be_empty
        expect(result[:work_item].relative_position).to be < item1.relative_position
      end
    end
  end
end
