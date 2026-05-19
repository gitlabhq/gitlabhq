# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ContainerRepositoryImagePlatform'], feature_category: :container_registry do
  fields = %i[architecture os os_version variant]

  it { expect(described_class.graphql_name).to eq('ContainerRepositoryImagePlatform') }
  it { expect(described_class).to require_graphql_authorizations(:read_container_image) }
  it { expect(described_class).to have_graphql_fields(fields) }
end
