require "spec_helper"

describe CalloutsHelper do
  let(:user) { create(:user) }

  before do
    allow(helper).to receive(:current_user).and_return(user)
  end

  describe '.show_gke_cluster_integration_callout?' do
    let(:project) { create(:project) }

    subject { helper.show_gke_cluster_integration_callout?('test_name', project) }

    context 'when user has not dismissed' do
      before do
        allow(helper).to receive(:user_dismissed?).and_return(false)
      end

      context 'when user is master' do
        before do
          allow(project).to receive_message_chain(:team, :master?).and_return(true)
        end

        it { is_expected.to be true }
      end

      context 'when user is not master' do
        before do
          allow(project).to receive_message_chain(:team, :master?).and_return(false)
        end

        it { is_expected.to be false }
      end
    end

    context 'when user dismissed' do
      before do
        allow(helper).to receive(:user_dismissed?).and_return(true)
      end

      it { is_expected.to be false }
    end
  end
end
