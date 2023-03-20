# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Members::BulkUpdateBase, feature_category: :subgroups do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group).tap { |group| group.add_owner(user) } }

  it 'raises a NotImplementedError error if the source_type method is called on the base class' do
    mutation = described_class.new(context: { current_user: user }, object: nil, field: nil)

    expect { mutation.resolve(group_id: group.to_gid.to_s) }.to raise_error(NotImplementedError)
  end
end
