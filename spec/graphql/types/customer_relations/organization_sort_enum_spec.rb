# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['OrganizationSort'] do
  specify { expect(described_class.graphql_name).to eq('OrganizationSort') }

  it_behaves_like 'common sort values'

  it 'exposes all the contact sort values' do
    expect(described_class.values.keys).to include(
      *%w[
        NAME_ASC
        NAME_DESC
        DESCRIPTION_ASC
        DESCRIPTION_DESC
        DEFAULT_RATE_ASC
        DEFAULT_RATE_DESC
      ]
    )
  end
end
