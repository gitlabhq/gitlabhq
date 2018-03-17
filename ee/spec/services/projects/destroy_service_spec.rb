require 'spec_helper'

describe Projects::DestroyService do
  let!(:user) { create(:user) }
  let!(:project) { create(:project, :repository, namespace: user.namespace) }
  let!(:project_id) { project.id }
  let!(:project_name) { project.name }
  let!(:project_path) { project.disk_path }
  let!(:wiki_path) { project.wiki.disk_path }
  let!(:storage_name) { project.repository_storage }
  let!(:storage_path) { project.repository_storage_path }

  subject { described_class.new(project, user, {}) }

  before do
    stub_container_registry_config(enabled: true)
    stub_container_registry_tags(repository: :any, tags: [])
  end

  context 'when project is a mirror' do
    it 'decrements capacity if mirror was scheduled' do
      max_capacity = Gitlab::CurrentSettings.mirror_max_capacity
      project_mirror = create(:project, :mirror, :repository, :import_scheduled)

      Gitlab::Mirror.increment_capacity(project_mirror.id)

      expect do
        described_class.new(project_mirror, project_mirror.owner, {}).execute
      end.to change { Gitlab::Mirror.available_capacity }.from(max_capacity - 1).to(max_capacity)
    end
  end

  context 'when running on a primary node' do
    set(:primary) { create(:geo_node, :primary) }
    set(:secondary) { create(:geo_node) }

    it 'logs an event to the Geo event log' do
      # Run Sidekiq immediately to check that renamed repository will be removed
      Sidekiq::Testing.inline! do
        expect { subject.execute }.to change(Geo::RepositoryDeletedEvent, :count).by(1)
      end
    end

    it 'does not log event to the Geo log if project deletion fails' do
      expect_any_instance_of(Project)
        .to receive(:destroy!).and_raise(StandardError.new('Other error message'))

      Sidekiq::Testing.inline! do
        expect { subject.execute }.not_to change(Geo::RepositoryDeletedEvent, :count)
      end
    end
  end

  context 'audit events' do
    include_examples 'audit event logging' do
      let(:operation) { subject.execute }
      let(:fail_condition!) do
        expect_any_instance_of(Project)
          .to receive(:destroy!).and_raise(StandardError.new('Other error message'))
      end
      let(:attributes) do
        {
           author_id: user.id,
           entity_id: project.id,
           entity_type: 'Project',
           details: {
             remove: 'project',
             author_name: user.name,
             target_id: project.full_path,
             target_type: 'Project',
             target_details: project.full_path
           }
         }
      end
    end
  end

  context 'system hooks exception' do
    before do
      allow_any_instance_of(SystemHooksService).to receive(:execute_hooks_for).and_raise('something went wrong')
    end

    it 'logs an audit event' do
      expect { subject.execute }.to change(AuditEvent, :count)
    end
  end
end
