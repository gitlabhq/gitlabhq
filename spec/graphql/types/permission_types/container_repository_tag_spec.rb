# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ContainerRepositoryTagPermissions'], feature_category: :container_registry do
  it 'has the expected fields' do
    expected_permissions = [:destroy_container_repository_tag]

    expect(described_class).to have_graphql_fields(expected_permissions).only
  end
end
