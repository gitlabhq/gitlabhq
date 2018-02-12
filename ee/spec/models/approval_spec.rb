require 'spec_helper'

describe Approval do
  subject { create(:approval) }

  it { is_expected.to be_valid }
end
