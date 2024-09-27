# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Onboarding::Status, feature_category: :onboarding do
  let_it_be(:member) { create(:group_member) }
  let_it_be(:user) { member.user }
  let_it_be(:source) { member.group }

  describe '.registration_path_params' do
    let(:params) { { some: 'thing' } }
    let(:extra_params) { { another_extra: 'param' } }

    subject { described_class.registration_path_params(params: params) }

    it { is_expected.to eq({}) }

    context 'when extra params are passed' do
      subject { described_class.registration_path_params(params: params, extra_params: extra_params) }

      it { is_expected.to eq({}) }
    end
  end

  describe '#single_invite?' do
    subject { described_class.new(nil, nil, user).single_invite? }

    context 'when there is only one member for the user' do
      context 'when the member source exists' do
        it { is_expected.to eq(true) }
      end
    end

    context 'when there is more than one member for the user' do
      before do
        create(:group_member, user: user)
      end

      it { is_expected.to eq(false) }
    end

    context 'when there are no members for the user' do
      let(:user) { build_stubbed(:user) }

      it { is_expected.to eq(false) }
    end
  end

  describe '#last_invited_member' do
    subject { described_class.new(nil, nil, user).last_invited_member }

    it { is_expected.to eq(member) }

    context 'when another member exists and is most recent' do
      let!(:last_member) { create(:group_member, user: user) }

      it { is_expected.to eq(last_member) }
    end

    context 'when there are no members' do
      let_it_be(:user) { build_stubbed(:user) }

      it { is_expected.to be_nil }
    end
  end

  describe '#last_invited_member_source' do
    subject { described_class.new(nil, nil, user).last_invited_member_source }

    context 'when a member exists' do
      it { is_expected.to eq(source) }
    end

    context 'when no members exist' do
      let_it_be(:user) { build_stubbed(:user) }

      it { is_expected.to be_nil }
    end

    context 'when another member exists and is most recent' do
      let!(:last_member_source) { create(:group_member, user: user).group }

      it { is_expected.to eq(last_member_source) }
    end
  end
end
