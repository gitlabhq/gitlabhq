# frozen_string_literal: true

require 'spec_helper'

describe UserFinder do
  describe '#execute' do
    context 'when the user exists' do
      it 'returns the user' do
        user = create(:user)
        found = described_class.new(id: user.id).execute

        expect(found).to eq(user)
      end
    end

    context 'when the user does not exist' do
      it 'returns nil' do
        found = described_class.new(id: 1).execute

        expect(found).to be_nil
      end
    end
  end

  describe '#execute!' do
    context 'when the user exists' do
      it 'returns the user' do
        user = create(:user)
        found = described_class.new(id: user.id).execute!

        expect(found).to eq(user)
      end
    end

    context 'when the user does not exist' do
      it 'raises ActiveRecord::RecordNotFound' do
        finder = described_class.new(id: 1)

        expect { finder.execute! }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
