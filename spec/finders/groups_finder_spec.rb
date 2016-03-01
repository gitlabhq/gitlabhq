require 'spec_helper'

describe GroupsFinder do
  describe '#execute' do
    let(:user) { create(:user) }
    let!(:private_group) { create(:group, visibility_level: 0) }
    let!(:internal_group) { create(:group, visibility_level: 10) }
    let!(:public_group) { create(:group, visibility_level: 20) }
    let(:finder) { described_class.new }

    describe 'execute' do
      describe 'without a user' do
        subject { finder.execute }

        it { is_expected.to eq([public_group]) }
      end

      describe 'with a user' do
        subject { finder.execute(user) }

        it { is_expected.to eq([public_group, internal_group]) }
      end
    end
  end
end
