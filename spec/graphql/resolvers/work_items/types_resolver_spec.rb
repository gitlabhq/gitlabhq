# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::WorkItems::TypesResolver do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group)        { create(:group) }

  before_all do
    group.add_developer(current_user)
  end

  describe '#resolve' do
    it 'returns all default work item types' do
      result = resolve(described_class, obj: group)

      expect(result.to_a).to match(WorkItems::Type.default.order_by_name_asc)
    end
  end
end
