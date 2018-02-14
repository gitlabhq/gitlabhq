require 'spec_helper'

describe LogFinder do
  let(:user) { create(:user) }

  describe '#execute' do
    before do
      create(:user_audit_event)
      create(:project_audit_event)
      create(:group_audit_event)
    end

    it 'finds all the events' do
      expect(described_class.new({}).execute.count).to eq(3)
    end

    context 'filtering by ID' do
      it 'finds the right user event' do
        expect(described_class.new(event_type: 'User', user_id: 1)
          .execute.map(&:entity_type)).to all(eq 'User')
      end

      it 'finds the right project event' do
        expect(described_class.new(event_type: 'Project', project_id: 1)
          .execute.map(&:entity_type)).to all(eq 'Project')
      end

      it 'finds the right group event' do
        expect(described_class.new(event_type: 'Group', group_id: 1)
          .execute.map(&:entity_type)).to all(eq 'Group')
      end
    end

    context 'filtering by type' do
      it 'finds the right user event' do
        expect(described_class.new(event_type: 'User')
          .execute.map(&:entity_type)).to all(eq 'User')
      end

      it 'finds the right project event' do
        expect(described_class.new(event_type: 'Project')
          .execute.map(&:entity_type)).to all(eq 'Project')
      end

      it 'finds the right group event' do
        expect(described_class.new(event_type: 'Group')
          .execute.map(&:entity_type)).to all(eq 'Group')
      end

      it 'finds all the events with no valid even type' do
        expect(described_class.new(event_type: '').execute.count).to eq(3)
      end
    end
  end
end
