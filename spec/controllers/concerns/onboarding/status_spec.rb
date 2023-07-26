# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Onboarding::Status, feature_category: :onboarding do
  let_it_be(:member) { create(:group_member) }
  let_it_be(:user) { member.user }
  let_it_be(:tasks_to_be_done) { %w[ci code] }
  let_it_be(:source) { member.group }

  describe '#continue_full_onboarding?' do
    subject { described_class.new(nil, {}, user).continue_full_onboarding? }

    it { is_expected.to eq(false) }
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

  describe '#invite_with_tasks_to_be_done?' do
    subject { described_class.new(nil, nil, user).invite_with_tasks_to_be_done? }

    context 'when there are tasks_to_be_done with one member' do
      let_it_be(:member) { create(:group_member, user: user, tasks_to_be_done: tasks_to_be_done) }

      it { is_expected.to eq(true) }
    end

    context 'when there are multiple members and the tasks_to_be_done is on only one of them' do
      before do
        create(:group_member, user: user, tasks_to_be_done: tasks_to_be_done)
      end

      it { is_expected.to eq(true) }
    end

    context 'when there are no tasks_to_be_done' do
      it { is_expected.to eq(false) }
    end

    context 'when there are no members' do
      let_it_be(:user) { build_stubbed(:user) }

      it { is_expected.to eq(false) }
    end
  end
end
