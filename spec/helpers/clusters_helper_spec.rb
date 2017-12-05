require 'spec_helper'

describe ClustersHelper do
  let(:cluster) { create(:cluster) }

  describe '.can_toggle_cluster' do
    let(:user) { create(:user) }

    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    subject { helper.can_toggle_cluster?(cluster) }

    context 'when user can update' do
      before do
        allow(helper).to receive(:can?).with(any_args).and_return(true)
      end

      context 'when cluster is created' do
        before do
          allow(cluster).to receive(:created?).and_return(true)
        end

        it { is_expected.to eq(true) }
      end

      context 'when cluster is not created' do
        before do
          allow(cluster).to receive(:created?).and_return(false)
        end

        it { is_expected.to eq(false) }
      end
    end

    context 'when user can not update' do
      before do
        allow(helper).to receive(:can?).with(any_args).and_return(false)
      end

      it { is_expected.to eq(false) }
    end
  end
end
