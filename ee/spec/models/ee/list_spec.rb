require 'rails_helper'

describe List do
  context 'when it is an assignee type' do
    let(:board) { create(:board) }

    subject { described_class.new(list_type: :assignee, board: board) }

    it { is_expected.to be_destroyable }
    it { is_expected.to be_movable }

    describe 'relationships' do
      it { is_expected.to belong_to(:user) }
    end

    describe 'validations' do
      it { is_expected.to validate_presence_of(:user) }
    end

    describe '#title' do
      it 'returns the username as title' do
        subject.user = create(:user, username: 'some_user')

        expect(subject.title).to eq('@some_user')
      end
    end
  end
end
