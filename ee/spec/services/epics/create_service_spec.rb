require 'spec_helper'

describe Epics::CreateService do
  let(:group) { create(:group, :internal)}
  let(:user) { create(:user) }
  let(:params) { { title: 'new epic', description: 'epic description' } }

  subject { described_class.new(group, user, params).execute }

  describe '#execute' do
    it 'creates one issue correctly' do
      allow(NewEpicWorker).to receive(:perform_async)

      expect { subject }.to change { Epic.count }.from(0).to(1)

      epic = Epic.last
      expect(epic).to be_persisted
      expect(epic.title).to eq('new epic')
      expect(epic.description).to eq('epic description')
      expect(NewEpicWorker).to have_received(:perform_async).with(epic.id, user.id)
    end
  end
end
