require 'spec_helper'

describe Types::MergeRequestType do
  it { expect(described_class).to expose_permissions_using(Types::PermissionTypes::MergeRequest) }
end
