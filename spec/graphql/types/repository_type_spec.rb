require 'spec_helper'

describe GitlabSchema.types['Repository'] do
  it { expect(described_class.graphql_name).to eq('Repository') }

  it { expect(described_class).to require_graphql_authorizations(:download_code) }

  it { is_expected.to have_graphql_field(:root_ref) }

  it { is_expected.to have_graphql_field(:tree) }
end
