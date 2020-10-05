# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['DesignCollection'] do
  it { expect(described_class).to require_graphql_authorizations(:read_design) }

  it 'has the expected fields' do
    expected_fields = %i[project issue designs versions version designAtVersion design copyState]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
