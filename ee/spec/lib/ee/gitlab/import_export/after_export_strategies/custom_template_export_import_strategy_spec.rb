require 'spec_helper'

describe EE::Gitlab::ImportExport::AfterExportStrategies::CustomTemplateExportImportStrategy do
  let!(:project_template) { create(:project, :repository, :with_export) }
  let(:project) { create(:project, :import_scheduled, import_type: 'gitlab_custom_project_template') }
  let(:user) { build(:user) }
  let(:repository_import_worker) { RepositoryImportWorker.new }

  subject { described_class.new(export_into_project_id: project.id) }

  before do
    stub_licensed_features(custom_project_templates: true)
    allow(RepositoryImportWorker).to receive(:new).and_return(repository_import_worker)
    allow(repository_import_worker).to receive(:perform)
  end

  describe 'validations' do
    it 'export_into_project_id must be present' do
      expect(described_class.new(export_into_project_id: nil)).to be_invalid
      expect(described_class.new(export_into_project_id: 1)).to be_valid
    end
  end

  describe '#execute' do
    it 'updates the project import_source with the path to import' do
      path = Tempfile.new.path

      allow(subject).to receive(:import_upload_path).and_return(path)
      expect(Project).to receive(:update).with(project.id, import_source: path).and_call_original

      subject.execute(user, project_template)

      expect(project.reload.import_source).to eq path
    end

    it 'imports repository' do
      expect(repository_import_worker).to receive(:perform).with(project.id).and_call_original

      subject.execute(user, project_template)

      expect(project_template.repository.ls_files('HEAD')).to eq project.repository.ls_files('HEAD')
    end

    it 'removes the exported project file after the import' do
      expect(project_template).to receive(:remove_exported_project_file)

      subject.execute(user, project_template)
    end

    describe 'export_file' do
      before do
        allow(subject).to receive(:project).and_return(project_template)
      end

      context 'without object storage' do
        it 'returns the local path' do
          subject.execute(user, project_template)

          expect(subject.send(:export_file)).not_to be_nil
        end
      end

      context 'with object storage' do
        let(:project_template) { create(:project, :with_object_export) }

        it 'returns the path from object storage' do
          subject.execute(user, project_template)

          expect(subject.send(:export_file)).not_to be_nil
        end
      end
    end
  end
end
