# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ContainerRepositoryTag'], feature_category: :container_registry do
  fields = %i[name path location digest revision short_revision
    total_size created_at user_permissions referrers published_at media_type protection]

  it { expect(described_class.graphql_name).to eq('ContainerRepositoryTag') }

  it { expect(described_class.description).to eq('A tag from a container repository') }

  it { expect(described_class).to require_graphql_authorizations(:read_container_image) }

  it { expect(described_class).to have_graphql_fields(fields) }

  it { expect(described_class).to expose_permissions_using(Types::PermissionTypes::ContainerRepositoryTag) }
end
