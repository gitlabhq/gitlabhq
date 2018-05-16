require 'spec_helper'
require Rails.root.join('ee', 'db', 'post_migrate', '20180502130136_migrate_mirror_attributes_data_from_projects_to_import_state.rb')

describe MigrateMirrorAttributesDataFromProjectsToImportState, :migration do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:import_state)  { table(:project_mirror_data) }

  describe '#up' do
    before do
      namespaces.create(id: 1, name: 'gitlab-org', path: 'gitlab-org')

      projects.create!(id: 1, namespace_id: 1, name: 'gitlab1',
                       path: 'gitlab1', import_error: "foo", import_status: :started,
                       mirror: true, import_url: generate(:url))
      projects.create!(id: 2, namespace_id: 1, name: 'gitlab2',
                       path: 'gitlab2', import_error: "foo", import_status: :finished,
                       mirror: false, import_url: generate(:url))

      import_state.create!(id: 1, project_id: 1)
      import_state.create!(id: 2, project_id: 2)
    end

    it 'migrates the mirror data to the import_state table' do
      expect(projects.joins("INNER JOIN project_mirror_data ON project_mirror_data.project_id = projects.id").count).to eq(2)

      expect do
        subject.up
      end.to change { projects.where(import_status: 'none').count }.from(0).to(1)

      expect(import_state.first.status).to eq("started")
      expect(import_state.first.last_error).to eq("foo")
      expect(import_state.last.status).to be_nil
      expect(import_state.last.last_error).to be_nil
    end
  end

  describe '#down' do
    before do
      namespaces.create(id: 1, name: 'gitlab-org', path: 'gitlab-org')

      projects.create!(id: 1, namespace_id: 1, name: 'gitlab1',
                       path: 'gitlab1', mirror: true, import_url: generate(:url))

      import_state.create!(id: 1, project_id: 1, status: :started, last_error: "foo")
    end

    it 'migrates the import_state mirror data into the projects table' do
      expect(projects.joins("INNER JOIN project_mirror_data ON project_mirror_data.project_id = projects.id").count).to eq(1)

      expect do
        subject.down
      end.to change { import_state.where(status: 'none').count }.from(0).to(1)

      expect(projects.first.import_status).to eq("started")
      expect(projects.first.import_error).to eq("foo")
    end
  end
end
