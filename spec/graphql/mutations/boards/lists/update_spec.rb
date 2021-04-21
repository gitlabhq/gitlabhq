# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Boards::Lists::Update do
  context 'on group issue boards' do
    let_it_be(:group)    { create(:group, :private) }
    let_it_be(:board)    { create(:board, group: group) }
    let_it_be(:reporter) { create(:user) }
    let_it_be(:guest)    { create(:user) }
    let_it_be(:list)     { create(:list, board: board, position: 0) }
    let_it_be(:list2)    { create(:list, board: board) }

    it_behaves_like 'update board list mutation'
  end
end
