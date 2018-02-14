require 'spec_helper'

describe NamespaceStatistics do
  it { is_expected.to belong_to(:namespace) }

  it { is_expected.to validate_presence_of(:namespace) }

  describe '#shared_runners_minutes' do
    let(:namespace_statistics) { build(:namespace_statistics, shared_runners_seconds: 120) }

    it { expect(namespace_statistics.shared_runners_minutes).to eq(2) }
  end
end
