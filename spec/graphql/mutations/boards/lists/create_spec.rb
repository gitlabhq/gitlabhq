# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Boards::Lists::Create, feature_category: :planning_views do
  let_it_be(:group) { create(:group, :private) }
  let_it_be(:board) { create(:board, group: group) }

  it_behaves_like 'board lists create mutation'
end
