require 'spec_helper'

describe API::ProjectImport do
  include ExternalAuthorizationServiceHelpers

  let(:export_path) { "#{Dir.tmpdir}/project_export_spec" }
  let(:user) { create(:user) }
  let(:file) { File.join(Rails.root, 'spec', 'features', 'projects', 'import_export', 'test_project_export.tar.gz') }
  let(:namespace) { create(:group) }
  before do
    allow_any_instance_of(Gitlab::ImportExport).to receive(:storage_path).and_return(export_path)

    namespace.add_owner(user)
  end

  after do
    FileUtils.rm_rf(export_path, secure: true)
  end

  describe 'POST /projects/import' do
    it 'overrides the classification label when the service is enabled' do
      enable_external_authorization_service_check
      override_params = { 'external_authorization_classification_label' => 'Hello world' }

      Sidekiq::Testing.inline! do
        post api('/projects/import', user),
             path: 'test-import',
             file: fixture_file_upload(file),
             namespace: namespace.id,
             override_params: override_params
      end
      import_project = Project.find(json_response['id'])

      expect(import_project.external_authorization_classification_label).to eq('Hello world')
    end
  end
end
