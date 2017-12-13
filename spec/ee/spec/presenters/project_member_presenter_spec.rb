require 'spec_helper'

describe ProjectMemberPresenter do
  let(:user) { double(:user) }
  let(:project) { double(:project) }
  let(:project_member) { double(:project_member, source: project) }
  let(:presenter) { described_class.new(project_member, current_user: user) }

  describe '#can_update?' do
    context 'when user cannot update_project_member but can override_project_member' do
      before do
        allow(presenter).to receive(:can?).with(user, :update_project_member, presenter).and_return(false)
        allow(presenter).to receive(:can?).with(user, :override_project_member, presenter).and_return(true)
      end

      it { expect(presenter.can_update?).to eq(true) }
    end

    context 'when user cannot update_project_member and cannot override_project_member' do
      before do
        allow(presenter).to receive(:can?).with(user, :update_project_member, presenter).and_return(false)
        allow(presenter).to receive(:can?).with(user, :override_project_member, presenter).and_return(false)
      end

      it { expect(presenter.can_update?).to eq(false) }
    end
  end
end
