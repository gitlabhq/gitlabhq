# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UserFinder do
  let_it_be(:user) { create(:user) }

  describe '#find_by_id' do
    context 'when the user exists' do
      it 'returns the user' do
        found = described_class.new(user.id).find_by_id

        expect(found).to eq(user)
      end
    end

    context 'when the user exists (id as string)' do
      it 'returns the user' do
        found = described_class.new(user.id.to_s).find_by_id

        expect(found).to eq(user)
      end
    end

    context 'when the user does not exist' do
      it 'returns nil' do
        found = described_class.new(-1).find_by_id

        expect(found).to be_nil
      end
    end
  end

  describe '#find_by_username' do
    context 'when the user exists' do
      it 'returns the user' do
        found = described_class.new(user.username).find_by_username

        expect(found).to eq(user)
      end
    end

    context 'when the user does not exist' do
      it 'returns nil' do
        found = described_class.new("non_existent_username").find_by_username

        expect(found).to be_nil
      end
    end
  end

  describe '#find_by_id_or_username' do
    context 'when the user exists (id)' do
      it 'returns the user' do
        found = described_class.new(user.id).find_by_id_or_username

        expect(found).to eq(user)
      end
    end

    context 'when the user exists (id as string)' do
      it 'returns the user' do
        found = described_class.new(user.id.to_s).find_by_id_or_username

        expect(found).to eq(user)
      end
    end

    context 'when the user exists (username)' do
      it 'returns the user' do
        found = described_class.new(user.username).find_by_id_or_username

        expect(found).to eq(user)
      end
    end

    context 'when the user does not exist (username)' do
      it 'returns nil' do
        found = described_class.new("non_existent_username").find_by_id_or_username

        expect(found).to be_nil
      end
    end

    context 'when the user does not exist' do
      it 'returns nil' do
        found = described_class.new(-1).find_by_id_or_username

        expect(found).to be_nil
      end
    end
  end

  describe '#find_by_id!' do
    context 'when the user exists' do
      it 'returns the user' do
        found = described_class.new(user.id).find_by_id!

        expect(found).to eq(user)
      end
    end

    context 'when the user exists (id as string)' do
      it 'returns the user' do
        found = described_class.new(user.id.to_s).find_by_id!

        expect(found).to eq(user)
      end
    end

    context 'when the user does not exist' do
      it 'raises ActiveRecord::RecordNotFound' do
        finder = described_class.new(-1)

        expect { finder.find_by_id! }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe '#find_by_username!' do
    context 'when the user exists' do
      it 'returns the user' do
        found = described_class.new(user.username).find_by_username!

        expect(found).to eq(user)
      end
    end

    context 'when the user does not exist' do
      it 'raises ActiveRecord::RecordNotFound' do
        finder = described_class.new("non_existent_username")

        expect { finder.find_by_username! }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe '#find_by_id_or_username!' do
    context 'when the user exists (id)' do
      it 'returns the user' do
        found = described_class.new(user.id).find_by_id_or_username!

        expect(found).to eq(user)
      end
    end

    context 'when the user exists (id as string)' do
      it 'returns the user' do
        found = described_class.new(user.id.to_s).find_by_id_or_username!

        expect(found).to eq(user)
      end
    end

    context 'when the user exists (username)' do
      it 'returns the user' do
        found = described_class.new(user.username).find_by_id_or_username!

        expect(found).to eq(user)
      end
    end

    context 'when the user does not exist (username)' do
      it 'raises ActiveRecord::RecordNotFound' do
        finder = described_class.new("non_existent_username")

        expect { finder.find_by_id_or_username! }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when the user does not exist' do
      it 'raises ActiveRecord::RecordNotFound' do
        finder = described_class.new(-1)

        expect { finder.find_by_id_or_username! }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
