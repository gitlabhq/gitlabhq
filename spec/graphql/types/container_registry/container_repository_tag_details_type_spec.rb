# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ContainerRepositoryTagDetails'], feature_category: :container_registry do
  fields = %i[name path location digest media_type total_size created_at published_at manifests platform]

  it { expect(described_class.graphql_name).to eq('ContainerRepositoryTagDetails') }
  it { expect(described_class.description).to eq('Details of a tag within a container repository') }
  it { expect(described_class).to require_graphql_authorizations(:read_container_image) }
  it { expect(described_class).to have_graphql_fields(fields) }
end
