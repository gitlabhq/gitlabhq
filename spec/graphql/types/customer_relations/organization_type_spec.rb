# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CustomerRelationsOrganization'] do
  let(:fields) { %i[id name default_rate description active created_at updated_at] }

  it { expect(described_class.graphql_name).to eq('CustomerRelationsOrganization') }
  it { expect(described_class).to have_graphql_fields(fields) }
  it { expect(described_class).to require_graphql_authorizations(:read_crm_organization) }
end
