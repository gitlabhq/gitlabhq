# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::BoardListResolver do
  include GraphqlHelpers
  include Gitlab::Graphql::Laziness

  let_it_be(:guest)         { create(:user) }
  let_it_be(:unauth_user)   { create(:user) }
  let_it_be(:group)         { create(:group, :private) }
  let_it_be(:group_label)   { create(:group_label, group: group, name: 'Development') }
  let_it_be(:board)         { create(:board, resource_parent: group) }
  let_it_be(:label_list)    { create(:list, board: board, label: group_label) }

  describe '#resolve' do
    subject { resolve_board_list(args: { id: global_id_of(label_list) }, current_user: current_user) }

    context 'with unauthorized user' do
      let(:current_user) { unauth_user }

      it { is_expected.to be_nil }
    end

    context 'when authorized' do
      let(:current_user) { guest }

      before do
        group.add_guest(guest)
      end

      it { is_expected.to eq label_list }
    end
  end

  def resolve_board_list(args: {}, current_user: user)
    force(resolve(described_class, obj: nil, args: args, ctx: { current_user: current_user }))
  end
end
