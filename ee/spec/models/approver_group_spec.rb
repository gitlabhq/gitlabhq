require 'spec_helper'

describe ApproverGroup do
  subject { create(:approver_group) }

  it { is_expected.to be_valid }
end
