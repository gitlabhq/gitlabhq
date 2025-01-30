# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Import/Export - project import integration test', :js, feature_category: :importers do
  let(:user) { create(:user) }
  let(:file) { File.join(Rails.root, 'spec', 'features', 'projects', 'import_export', 'test_project_export.tar.gz') }
  let(:export_path) { "#{Dir.tmpdir}/import_file_spec" }

  before do
    stub_application_setting(import_sources: ['gitlab_project'])
    stub_uploads_object_storage(FileUploader)
    stub_feature_flags(new_project_creation_form: false)
    allow_next_instance_of(Gitlab::ImportExport) do |instance|
      allow(instance).to receive(:storage_path).and_return(export_path)
    end
    sign_in(user)
  end

  after do
    FileUtils.rm_rf(export_path, secure: true)
  end

  context 'when selecting the namespace' do
    let(:user) { create(:admin) }
    let!(:namespace) { user.namespace }
    let(:random_hex) { SecureRandom.hex }
    let(:project_name) { 'Test Project Name' + random_hex }
    let(:project_path) { 'test-project-name' + random_hex }

    it 'user imports an exported project successfully', :sidekiq_might_not_need_inline do
      visit new_project_path
      click_link 'Import project'
      click_link 'GitLab export'

      fill_in :name, with: 'Test Project Name', visible: true
      fill_in :path, with: 'test-project-path', visible: true
      attach_file('file', file)

      expect { click_button 'Import project' }.to change { Project.count }.by(1)

      project = Project.last
      expect(project).not_to be_nil
      expect(page).to have_content("Project 'Test Project Name' is being imported")
    end

    it 'invalid project' do
      project = create(:project, namespace: user.namespace)

      visit new_project_path

      click_link 'Import project'
      click_link 'GitLab export'
      fill_in :name, with: project.name, visible: true
      attach_file('file', file)
      click_button 'Import project'

      page.within('.flash-container') do
        expect(page).to have_content('Project could not be imported')
      end
    end
  end
end
