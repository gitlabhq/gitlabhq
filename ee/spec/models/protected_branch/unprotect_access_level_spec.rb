require 'spec_helper'

describe ProtectedBranch::UnprotectAccessLevel do
  it { is_expected.to validate_inclusion_of(:access_level).in_array([Gitlab::Access::MASTER, Gitlab::Access::DEVELOPER, Gitlab::Access::NO_ACCESS]) }
end
