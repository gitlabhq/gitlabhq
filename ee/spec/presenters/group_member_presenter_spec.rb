require 'spec_helper'

describe GroupMemberPresenter do
  let(:user) { double(:user) }
  let(:group) { double(:group) }
  let(:group_member) { double(:group_member, source: group) }
  let(:presenter) { described_class.new(group_member, current_user: user) }

  describe '#can_update?' do
    context 'when user cannot update_group_member but can override_group_member' do
      before do
        allow(presenter).to receive(:can?).with(user, :update_group_member, presenter).and_return(false)
        allow(presenter).to receive(:can?).with(user, :override_group_member, presenter).and_return(true)
      end

      it { expect(presenter.can_update?).to eq(true) }
    end

    context 'when user cannot update_group_member and cannot override_group_member' do
      before do
        allow(presenter).to receive(:can?).with(user, :update_group_member, presenter).and_return(false)
        allow(presenter).to receive(:can?).with(user, :override_group_member, presenter).and_return(false)
      end

      it { expect(presenter.can_update?).to eq(false) }
    end
  end
end
