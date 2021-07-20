# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Import/Export - project import integration test', :js do
  include GitHelpers

  let(:user) { create(:user) }
  let(:file) { File.join(Rails.root, 'spec', 'features', 'projects', 'import_export', 'test_project_export.tar.gz') }
  let(:export_path) { "#{Dir.tmpdir}/import_file_spec" }

  before do
    stub_uploads_object_storage(FileUploader)
    allow_next_instance_of(Gitlab::ImportExport) do |instance|
      allow(instance).to receive(:storage_path).and_return(export_path)
    end
    gitlab_sign_in(user)
  end

  after do
    FileUtils.rm_rf(export_path, secure: true)
  end

  context 'when selecting the namespace' do
    let(:user) { create(:admin) }
    let!(:namespace) { user.namespace }
    let(:randomHex) { SecureRandom.hex }
    let(:project_name) { 'Test Project Name' + randomHex }
    let(:project_path) { 'test-project-name' + randomHex }

    it 'user imports an exported project successfully', :sidekiq_might_not_need_inline do
      visit new_project_path
      click_import_project
      click_link 'GitLab export'

      fill_in :name, with: 'Test Project Name', visible: true
      fill_in :path, with: 'test-project-path', visible: true
      attach_file('file', file)

      expect { click_button 'Import project' }.to change { Project.count }.by(1)

      project = Project.last
      expect(project).not_to be_nil
      expect(page).to have_content("Project 'test-project-path' is being imported")
    end

    it 'invalid project' do
      project = create(:project, namespace: user.namespace)

      visit new_project_path

      click_import_project
      click_link 'GitLab export'
      fill_in :name, with: project.name, visible: true
      attach_file('file', file)
      click_button 'Import project'

      page.within('.flash-container') do
        expect(page).to have_content('Project could not be imported')
      end
    end
  end

  def click_import_project
    find('[data-qa-panel-name="import_project"]').click
  end
end
