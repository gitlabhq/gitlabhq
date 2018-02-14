require 'spec_helper'

describe Plan do
  describe 'associations' do
    it { is_expected.to have_many(:namespaces) }
  end
end
