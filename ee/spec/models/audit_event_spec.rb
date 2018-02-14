require 'rails_helper'

RSpec.describe AuditEvent, type: :model do
  describe 'relationships' do
    it { is_expected.to belong_to(:user).with_foreign_key('author_id') }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:author_id) }
    it { is_expected.to validate_presence_of(:entity_id) }
    it { is_expected.to validate_presence_of(:entity_type) }
  end

  describe '#author_name' do
    context 'when user exists' do
      let(:user) { create(:user, name: 'John Doe') }

      subject(:event) { described_class.new(user: user) }

      it 'returns user name' do
        expect(event.author_name).to eq 'John Doe'
      end
    end

    context 'when user does not exists anymore' do
      subject(:event) { described_class.new(author_id: 99999) }

      context 'when details contains author_name' do
        it 'returns author_name' do
          subject.details = { author_name: 'John Doe' }

          expect(event.author_name).to eq 'John Doe'
        end
      end

      context 'when details does not contains author_name' do
        it 'returns nil' do
          subject.details = {}

          expect(subject.author_name).to eq nil
        end
      end
    end
  end

  describe '#entity' do
    context 'when entity exists' do
      let(:user) { create(:user, name: 'John Doe') }

      subject(:event) { described_class.new(entity_id: user.id, entity_type: user.class.name) }

      it 'returns the entity object' do
        expect(event.entity).to eq user
      end
    end

    context 'when entity does not exist' do
      subject(:event) { described_class.new(entity_id: 99999, entity_type: 'User') }

      it 'returns nil' do
        expect(event.entity).to be_blank
      end
    end
  end

  describe '#present' do
    it 'returns a presenter' do
      expect(subject.present).to be_an_instance_of(AuditEventPresenter)
    end
  end
end
