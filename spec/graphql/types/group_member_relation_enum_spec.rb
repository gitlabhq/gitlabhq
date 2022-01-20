# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::GroupMemberRelationEnum do
  specify { expect(described_class.graphql_name).to eq('GroupMemberRelation') }

  it 'exposes all the existing group member relation type values' do
    expect(described_class.values.keys).to contain_exactly('DIRECT', 'INHERITED', 'DESCENDANTS', 'SHARED_FROM_GROUPS')
  end
end
