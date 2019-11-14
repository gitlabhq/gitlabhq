# frozen_string_literal: true

require 'spec_helper'

describe 'Import/Export - project import integration test', :js do
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

    context 'prefilled the path' do
      it 'user imports an exported project successfully', :sidekiq_might_not_need_inline do
        visit new_project_path

        fill_in :project_name, with: project_name, visible: true
        click_import_project_tab
        click_link 'GitLab export'

        expect(page).to have_content('Import an exported GitLab project')
        expect(URI.parse(current_url).query).to eq("namespace_id=#{namespace.id}&name=#{ERB::Util.url_encode(project_name)}&path=#{project_path}")

        attach_file('file', file)
        click_on 'Import project'

        expect(Project.count).to eq(1)

        project = Project.last
        expect(project).not_to be_nil
        expect(project.description).to eq("Foo Bar")
        expect(project.issues).not_to be_empty
        expect(project.merge_requests).not_to be_empty
        expect(wiki_exists?(project)).to be true
        expect(project.import_state.status).to eq('finished')
      end
    end

    context 'path is not prefilled' do
      it 'user imports an exported project successfully', :sidekiq_might_not_need_inline do
        visit new_project_path
        click_import_project_tab
        click_link 'GitLab export'

        fill_in :name, with: 'Test Project Name', visible: true
        fill_in :path, with: 'test-project-path', visible: true
        attach_file('file', file)

        expect { click_on 'Import project' }.to change { Project.count }.by(1)

        project = Project.last
        expect(project).not_to be_nil
        expect(page).to have_content("Project 'test-project-path' is being imported")
      end
    end
  end

  it 'invalid project' do
    project = create(:project, namespace: user.namespace)

    visit new_project_path

    fill_in :project_name, with: project.name, visible: true
    click_import_project_tab
    click_link 'GitLab export'
    attach_file('file', file)
    click_on 'Import project'

    page.within('.flash-container') do
      expect(page).to have_content('Project could not be imported')
    end
  end

  def wiki_exists?(project)
    wiki = ProjectWiki.new(project)
    wiki.repository.exists? && !wiki.repository.empty?
  end

  def click_import_project_tab
    find('#import-project-tab').click
  end
end
