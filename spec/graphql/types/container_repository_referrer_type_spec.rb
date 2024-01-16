# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ContainerRepositoryReferrer'], feature_category: :container_registry do
  fields = %i[artifact_type digest user_permissions]

  it { expect(described_class.graphql_name).to eq('ContainerRepositoryReferrer') }

  it { expect(described_class.description).to eq('A referrer for a container repository tag') }

  it { expect(described_class).to require_graphql_authorizations(:read_container_image) }

  it { expect(described_class).to have_graphql_fields(fields) }

  it { expect(described_class).to expose_permissions_using(Types::PermissionTypes::ContainerRepositoryTag) }
end
