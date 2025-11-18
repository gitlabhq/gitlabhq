# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Authz::AccessTokens::BoundaryEnum, feature_category: :permissions do
  specify { expect(described_class.graphql_name).to eq('PermissionBoundary') }

  it 'exposes all the scope values' do
    expect(described_class.values).to match(
      'PROJECT' => have_attributes(value: 'project'),
      'GROUP' => have_attributes(value: 'group'),
      'USER' => have_attributes(value: 'user'),
      'INSTANCE' => have_attributes(value: 'instance')
    )
  end
end
