require 'spec_helper'

describe Types::Ci::PipelineType do
  it { expect(described_class.graphql_name).to eq('Pipeline') }

  it { expect(described_class).to expose_permissions_using(Types::PermissionTypes::Ci::Pipeline) }
end
