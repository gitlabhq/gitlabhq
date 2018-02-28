require 'spec_helper'

describe EE::Audit::ProjectChangesAuditor do
  describe '.audit_changes' do
    let!(:user) { create(:user) }
    let!(:project) { create(:project, visibility_level: 0) }
    let(:foo_instance) { described_class.new(user, project) }

    before do
      stub_licensed_features(extended_audit_events: true)
    end

    describe 'non audit changes' do
      it 'does not call the audit event service' do
        project.update!(description: 'new description')

        expect { foo_instance.execute }.not_to change { SecurityEvent.count }
      end
    end

    describe 'audit changes' do
      it 'creates an event when the visibility change' do
        project.update!(visibility_level: 20)

        expect { foo_instance.execute }.to change { SecurityEvent.count }.by(1)
        expect(SecurityEvent.last.details[:change]).to eq 'visibility'
      end

      it 'creates an event when the name change' do
        project.update!(name: 'new name')

        expect { foo_instance.execute }.to change { SecurityEvent.count }.by(1)
        expect(SecurityEvent.last.details[:change]).to eq 'name'
      end

      it 'creates an event when the path change' do
        project.update!(path: 'newpath')

        expect { foo_instance.execute }.to change { SecurityEvent.count }.by(1)
        expect(SecurityEvent.last.details[:change]).to eq 'path'
      end

      it 'creates an event when the namespace change' do
        new_namespace = create(:namespace)

        project.update!(namespace: new_namespace)

        expect { foo_instance.execute }.to change { SecurityEvent.count }.by(1)
        expect(SecurityEvent.last.details[:change]).to eq 'namespace'
      end
    end
  end
end
