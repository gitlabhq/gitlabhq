require 'spec_helper'

describe GitlabSchema.types['Metadata'] do
  it { expect(described_class.graphql_name).to eq('Metadata') }
end
