require 'spec_helper'

describe Project, benchmark: true do
  describe '.find_with_namespace' do
    let(:group)   { create(:group, name: 'sisinmaru') }
    let(:project) { create(:project, name: 'maru', namespace: group) }

    describe 'using a capitalized namespace' do
      benchmark_subject { described_class.find_with_namespace('sisinmaru/MARU') }

      it { is_expected.to iterate_per_second(600) }
    end

    describe 'using a lowercased namespace' do
      benchmark_subject { described_class.find_with_namespace('sisinmaru/maru') }

      it { is_expected.to iterate_per_second(600) }
    end
  end
end
