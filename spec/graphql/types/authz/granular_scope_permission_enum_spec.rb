# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Authz::GranularScopePermissionEnum, feature_category: :permissions do
  specify { expect(described_class.graphql_name).to eq('GranularScopePermission') }

  it 'exposes all the granular scope permissions available for access tokens' do
    expect(described_class.values.keys)
      .to match_array(::Authz::PermissionGroups::Assignable.all_permissions.uniq.map(&:to_s).map(&:upcase))
  end
end
