require 'spec_helper'

describe Project, benchmark: true do
  describe '.trending' do
    let(:group)    { create(:group) }
    let(:project1) { create(:empty_project, :public, group: group) }
    let(:project2) { create(:empty_project, :public, group: group) }

    let(:iterations) { 500 }

    before do
      2.times do
        create(:note_on_commit, project: project1)
      end

      create(:note_on_commit, project: project2)
    end

    describe 'without an explicit start date' do
      benchmark_subject { described_class.trending.to_a }

      it { is_expected.to iterate_per_second(iterations) }
    end

    describe 'with an explicit start date' do
      let(:date) { 1.month.ago }

      benchmark_subject { described_class.trending(date).to_a }

      it { is_expected.to iterate_per_second(iterations) }
    end
  end

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
