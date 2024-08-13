# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::WorkItems::Hierarchy::Reorder, feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:current_work_item) { create(:work_item, :task, project: project) }
  let_it_be(:parent_work_item) { create(:work_item, project: project) }

  subject(:mutation) { described_class.new(object: nil, context: query_context, field: nil) }

  describe '#ready?' do
    let(:current_user) { developer }
    let(:current_gid) { current_work_item.to_gid.to_s }
    let(:parent_gid) { parent_work_item.to_gid.to_s }
    let(:valid_arguments) { { id: current_gid, parent_id: parent_gid } }

    it { is_expected.to be_ready(**valid_arguments) }

    context 'when arguments are invalid' do
      context 'when a adjacentWorkItemId argument is missing' do
        let(:arguments) { { id: current_gid, relative_position: "AFTER" } }

        it 'raises error' do
          expect { mutation.ready?(**arguments) }
            .to raise_error(
              Gitlab::Graphql::Errors::ArgumentError,
              'Both adjacentWorkItemId and relativePosition are required.'
            )
        end
      end

      context "when adjacent item's parent doesn't match the work item's parent" do
        let_it_be(:invalid_adjacent) { create(:work_item, :task, project: project) }

        let(:arguments) do
          {
            id: current_gid,
            adjacent_work_item_id: invalid_adjacent.to_gid.to_s,
            parent_id: parent_gid,
            relative_position: "AFTER"
          }
        end

        it 'raises error' do
          expect { mutation.ready?(**arguments) }
            .to raise_error(
              Gitlab::Graphql::Errors::ArgumentError,
              "The adjacent work item's parent must match the moving work item's parent."
            )
        end
      end
    end
  end
end
