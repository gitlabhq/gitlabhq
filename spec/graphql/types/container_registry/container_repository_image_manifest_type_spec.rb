# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ContainerRepositoryImageManifest'], feature_category: :container_registry do
  fields = %i[digest media_type platform size]

  it { expect(described_class.graphql_name).to eq('ContainerRepositoryImageManifest') }
  it { expect(described_class).to require_graphql_authorizations(:read_container_image) }
  it { expect(described_class).to have_graphql_fields(fields) }
end
