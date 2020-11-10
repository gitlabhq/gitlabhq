# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ContainerRepositoryTag'] do
  fields = %i[name path location digest revision short_revision total_size created_at can_delete]

  it { expect(described_class.graphql_name).to eq('ContainerRepositoryTag') }

  it { expect(described_class.description).to eq('A tag from a container repository') }

  it { expect(described_class).to require_graphql_authorizations(:read_container_image) }

  it { expect(described_class).to have_graphql_fields(fields) }
end
