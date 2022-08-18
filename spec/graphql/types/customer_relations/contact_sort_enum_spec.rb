# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ContactSort'] do
  specify { expect(described_class.graphql_name).to eq('ContactSort') }

  it_behaves_like 'common sort values'

  it 'exposes all the contact sort values' do
    expect(described_class.values.keys).to include(
      *%w[
        FIRST_NAME_ASC
        FIRST_NAME_DESC
        LAST_NAME_ASC
        LAST_NAME_DESC
        EMAIL_ASC
        EMAIL_DESC
        PHONE_ASC
        PHONE_DESC
        DESCRIPTION_ASC
        DESCRIPTION_DESC
        ORGANIZATION_ASC
        ORGANIZATION_DESC
      ]
    )
  end
end
