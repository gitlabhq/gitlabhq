require 'spec_helper'

describe TrendingProjectsFinder do
  let(:user) { build(:user) }

  describe '#execute' do
    describe 'without an explicit start date' do
      subject { described_class.new }

      it 'returns the trending projects' do
        relation = double(:ar_relation)

        allow(subject).to receive(:projects_for)
          .with(user)
          .and_return(relation)

        allow(relation).to receive(:trending)
          .with(an_instance_of(ActiveSupport::TimeWithZone))
      end
    end

    describe 'with an explicit start date' do
      let(:date) { 2.months.ago }

      subject { described_class.new }

      it 'returns the trending projects' do
        relation = double(:ar_relation)

        allow(subject).to receive(:projects_for)
          .with(user)
          .and_return(relation)

        allow(relation).to receive(:trending)
          .with(date)
      end
    end
  end
end
