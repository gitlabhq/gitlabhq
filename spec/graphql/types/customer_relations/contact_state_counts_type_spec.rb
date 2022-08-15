# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ContactStateCounts'] do
  let(:fields) do
    %w[
      all
      active
      inactive
    ]
  end

  it { expect(described_class.graphql_name).to eq('ContactStateCounts') }
  it { expect(described_class).to have_graphql_fields(fields) }
  it { expect(described_class).to require_graphql_authorizations(:read_crm_contact) }
end
